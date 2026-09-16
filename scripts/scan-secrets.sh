#!/bin/sh
# agent-ready — scan-secrets.sh
#
# Scans a git repository for leaked credentials: every branch's full history
# (added lines only), plus the working tree and ignore coverage. Prints a report
# and exits non-zero when anything needs a human decision.
#
# Usage:  sh scripts/scan-secrets.sh [path-to-repo]
# Exit:   0 clean · 1 HIGH or REVIEW findings · 2 not a git repo
#
# Severity:
#   HIGH    token-shaped strings (JWT, cloud/API keys, private keys, URL creds),
#           env files tracked in git, ignored files that were force-added
#   REVIEW  credential-like assignments (PASSWORD=…, TOKEN=…) — confirm each is
#           a placeholder or an obviously-fake test value; secret-bearing local
#           files that are NOT gitignored; env-example values that aren't
#           placeholders
#   INFO    suspicious file paths that were committed at some point
#
# POSIX sh + git + grep + awk + sort. No bash, no Python, no Node.

set -u

repo="${1:-.}"
cd "$repo" 2>/dev/null || { echo "scan-secrets: cannot cd to $repo" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "scan-secrets: not a git repository" >&2; exit 2; }

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t agent-ready)"
trap 'rm -rf "$tmp"' EXIT INT TERM

high=0
review=0
info=0

say() { printf '%s\n' "$*"; }
hr()  { say "------------------------------------------------------------------"; }

# ---------------------------------------------------------------------------
# Pattern files. Quoted heredocs: nothing is expanded.
# ---------------------------------------------------------------------------
cat >"$tmp/high.re" <<'EOF'
eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
gh[pousr]_[A-Za-z0-9]{36}
github_pat_[A-Za-z0-9_]{22,}
AKIA[0-9A-Z]{16}
ASIA[0-9A-Z]{16}
sk-ant-[A-Za-z0-9_-]{20,}
sk-[A-Za-z0-9]{32,}
sk_live_[0-9A-Za-z]{24,}
rk_live_[0-9A-Za-z]{24,}
xox[baprs]-[0-9A-Za-z-]{10,}
hooks\.slack\.com/services/T[A-Za-z0-9]+/B[A-Za-z0-9]+/[A-Za-z0-9]+
AIza[0-9A-Za-z_-]{35}
SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}
-----BEGIN [A-Z ]*PRIVATE KEY
[a-z][a-z0-9+.-]*://[^/[:space:]:@"']+:[^@[:space:]"']+@[^/[:space:]"']+
authToken=[A-Za-z0-9._-]{30,}
\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}
EOF

# A: key followed by a QUOTED literal of 6+ chars (code, YAML, JSON). Case-insensitive.
cat >"$tmp/review-quoted.re" <<'EOF'
(SECRET|TOKEN|PASSWORD|PASSWD|API_?KEY|PRIVATE_KEY|ACCESS_KEY|AUTH_KEY|CLIENT_SECRET)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*["'][^"']{6,}["']
EOF
# B: UPPER_SNAKE key with an UNQUOTED value to end of line (.env files, YAML, shell exports).
cat >"$tmp/review-env.re" <<'EOF'
\| [[:space:]-]*(export[[:space:]]+)?[A-Z][A-Z0-9_]*(SECRET|TOKEN|PASSWORD|PASSWD|API_?KEY|PRIVATE_KEY|ACCESS_KEY|CLIENT_SECRET)[A-Z0-9_]*[[:space:]]*[:=][[:space:]]*[^[:space:]"'{$][^[:space:]]{5,}$
EOF

# Values that are clearly placeholders, not secrets. Applied to HIGH and REVIEW.
cat >"$tmp/placeholder.re" <<'EOF'
<[^>]*>
\$\{
process\.env
os\.environ
getenv\(
example
change-?me
your[-_]
xxx
placeholder
dummy
not-a-real
ci-only
data-testid
[:=][[:space:]]*[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_]
EOF

# Files whose content is noise for this purpose.
cat >"$tmp/skipfiles.re" <<'EOF'
(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb|Cargo\.lock|poetry\.lock|Pipfile\.lock|go\.sum|composer\.lock|Gemfile\.lock)$
\.min\.(js|css)$
\.map$
(^|/)(node_modules|vendor|dist|build|\.next|target)/
\.(png|jpg|jpeg|gif|ico|svg|woff2?|ttf|pdf|zip)$
EOF

# Path names that deserve a look if they were ever committed.
cat >"$tmp/suspicious-paths.re" <<'EOF'
(^|/)\.env($|\.)
\.(pem|key|p12|pfx|jks|keystore|asc|gpg)$
\.(db|sqlite|sqlite3|bak|dump)$
(^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519)([./]|$)
(^|/)(credentials?|secrets?)([./]|$)
(^|/)\.(npmrc|netrc|pypirc)$
(^|/)\.claude/settings
(^|/)\.vercel/
\.zip$
EOF

say "agent-ready secrets scan — $(git rev-parse --show-toplevel)"
say "branches: $(git for-each-ref --format='%(refname:short)' refs/heads | tr '\n' ' ')"
say "commits:  $(git rev-list --all --count)"
hr

# ---------------------------------------------------------------------------
# 1. Suspicious paths ever committed (any branch)                       [INFO]
# ---------------------------------------------------------------------------
say "1. Paths ever committed that deserve a look"
git log --all --name-only --format="" 2>/dev/null | sort -u >"$tmp/paths.txt"
grep -E -f "$tmp/suspicious-paths.re" "$tmp/paths.txt" \
  | grep -vE '\.env\.(example|sample|template)$' >"$tmp/paths-hit.txt" || true
if [ -s "$tmp/paths-hit.txt" ]; then
  while IFS= read -r p; do
    last="$(git log --all --format='%h %ad' --date=short -1 -- "$p" 2>/dev/null)"
    say "   INFO   $p   (last touched $last)"
    info=$((info + 1))
  done <"$tmp/paths-hit.txt"
  say "   -> Check what each one contained: git show <commit>:<path>"
else
  say "   none"
fi
hr

# ---------------------------------------------------------------------------
# 2. Added lines across the whole history                        [HIGH/REVIEW]
# ---------------------------------------------------------------------------
say "2. Added lines in every commit on every branch"
git log -p --all --format='@@COMMIT %h' 2>/dev/null \
  | awk -v skip="$tmp/skipfiles.re" '
      BEGIN { while ((getline line < skip) > 0) if (line != "") pats[n++] = line }
      /^@@COMMIT /  { c = $2; next }
      /^\+\+\+ /    { f = $2; sub(/^b\//, "", f); skipf = 0
                      for (i = 0; i < n; i++) if (f ~ pats[i]) { skipf = 1; break }
                      next }
      /^\+/ && !/^\+\+\+/ { if (!skipf) print c " | " f " | " substr($0, 2) }
    ' >"$tmp/added.txt"

say "   scanned $(wc -l <"$tmp/added.txt" | tr -d ' ') added lines"

grep -E -f "$tmp/high.re" "$tmp/added.txt" 2>/dev/null \
  | grep -vE -f "$tmp/placeholder.re" >"$tmp/high-hit.txt" || true
if [ -s "$tmp/high-hit.txt" ]; then
  say "   HIGH — token-shaped strings (commit | file | line):"
  cut -c1-200 "$tmp/high-hit.txt" | sed 's/^/     /'
  high=$((high + $(wc -l <"$tmp/high-hit.txt")))
fi

{ grep -iE -f "$tmp/review-quoted.re" "$tmp/added.txt" 2>/dev/null
  grep -E  -f "$tmp/review-env.re"    "$tmp/added.txt" 2>/dev/null; } \
  | sort -u \
  | grep -vE -f "$tmp/placeholder.re" \
  | grep -vE '^[^|]+\| [^|]*\.(md|txt|rst)[[:space:]]*\|' >"$tmp/review-hit.txt" || true
if [ -s "$tmp/review-hit.txt" ]; then
  say "   REVIEW — credential-like assignments; confirm each is a placeholder or an"
  say "            obviously-fake test value never used anywhere real:"
  cut -c1-200 "$tmp/review-hit.txt" | sort -u -t'|' -k3 | sed 's/^/     /' | head -60
  n="$(cut -d'|' -f3 "$tmp/review-hit.txt" | sort -u | wc -l | tr -d ' ')"
  [ "$n" -gt 60 ] && say "     … ($n distinct values; showing 60)"
  review=$((review + n))
fi
[ -s "$tmp/high-hit.txt" ] || [ -s "$tmp/review-hit.txt" ] || say "   none"
hr

# ---------------------------------------------------------------------------
# 3. Working tree and ignore coverage                            [HIGH/REVIEW]
# ---------------------------------------------------------------------------
say "3. Working tree"
wt_before=$((high + review))

# 3a. Env files tracked in git (not examples)
git ls-files | grep -E '(^|/)\.env($|\.)' | grep -vE '\.(example|sample|template)$' >"$tmp/tracked-env.txt" || true
if [ -s "$tmp/tracked-env.txt" ]; then
  say "   HIGH — env files tracked in git:"
  sed 's/^/     /' "$tmp/tracked-env.txt"
  high=$((high + $(wc -l <"$tmp/tracked-env.txt")))
fi

# 3b. Files tracked despite matching .gitignore (force-added)
git ls-files -i -c --exclude-standard >"$tmp/forced.txt" 2>/dev/null || true
if [ -s "$tmp/forced.txt" ]; then
  say "   HIGH — tracked although .gitignore matches them (force-added?):"
  sed 's/^/     /' "$tmp/forced.txt"
  high=$((high + $(wc -l <"$tmp/forced.txt")))
fi

# 3c. Secret-bearing files present locally but not ignored
find . -path ./.git -prune -o -path ./node_modules -prune -o -type f -print 2>/dev/null \
  | sed 's|^\./||' \
  | grep -E -f "$tmp/suspicious-paths.re" \
  | grep -vE '\.env\.(example|sample|template)$|\.zip$' >"$tmp/local-secretish.txt" || true
if [ -s "$tmp/local-secretish.txt" ]; then
  while IFS= read -r p; do
    if git check-ignore -q -- "$p" 2>/dev/null; then
      :
    elif git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      : # tracked: already reported in 3a/3b if it matters
    else
      say "   REVIEW — present and NOT gitignored (a 'git add -A' would commit it): $p"
      review=$((review + 1))
    fi
  done <"$tmp/local-secretish.txt"
fi

# 3d. Env example files should hold placeholders only
for ex in $(git ls-files | grep -E '\.env\.(example|sample|template)$' 2>/dev/null); do
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=.+' "$ex" \
    | grep -vE '=[[:space:]]*("")?$|=[[:space:]]*'"''"'$' \
    | grep -vE -f "$tmp/placeholder.re" \
    | grep -vE '=[[:space:]]*"?(file:|http://localhost|localhost|127\.0\.0\.1|0\.0\.0\.0|true|false|[0-9]+)' >"$tmp/ex-hit.txt" || true
  if [ -s "$tmp/ex-hit.txt" ]; then
    say "   REVIEW — $ex has values that don't look like placeholders:"
    sed 's/^/     /' "$tmp/ex-hit.txt"
    review=$((review + $(wc -l <"$tmp/ex-hit.txt")))
  fi
done

[ $((high + review)) -gt "$wt_before" ] || say "   clean"
hr

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
say "Summary: HIGH=$high  REVIEW=$review  INFO=$info"
if [ "$high" -gt 0 ]; then
  say "HIGH findings are real credential shapes. If any is genuine and the repo has"
  say "been pushed, rotate it now; if it has not been pushed, rewrite history first."
fi
if [ "$review" -gt 0 ]; then
  say "REVIEW findings need a human answer: is each value a placeholder, or a test"
  say "value that has never been used for anything real? Ask; do not assume."
fi
if [ "$high" -eq 0 ] && [ "$review" -eq 0 ]; then
  say "No credential-shaped strings or unguarded secret files found."
  say "Remember: a clean scan is a snapshot. Enable the host's secret scanning and"
  say "push protection for the ongoing guard."
fi

[ "$high" -eq 0 ] && [ "$review" -eq 0 ] && exit 0
exit 1

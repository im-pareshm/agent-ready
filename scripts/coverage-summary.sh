#!/bin/sh
# agent-ready — coverage-summary.sh
#
# "Do the tests reach what I changed?"
#
# Reads one or more lcov files — every mainstream test runner can write one — and
# prints a Markdown coverage report: line and branch totals for each file given
# (one row per suite; suites are not merged into one number), and, with --base,
# the coverage of every file changed since that ref, committed or not. A changed
# file at 0% is flagged, and so is a changed source file the report doesn't list
# at all ("source" = an extension the report covers, not a test file).
#
# Report only: it never fails over a number. Copy it into a repo so CI can write
# the report into the job summary (reference/ci-principles.md §12).
#
# Usage:
#   sh scripts/coverage-summary.sh coverage/lcov.info
#   sh scripts/coverage-summary.sh --base origin/main web/coverage/lcov.info server/lcov.info
#   sh scripts/coverage-summary.sh --base "origin/$GITHUB_BASE_REF" lcov.info >> "$GITHUB_STEP_SUMMARY"
#
# Paths in the lcov (SF: lines) may be absolute — POSIX, Windows (D:\...) or Git
# Bash (/d/...) — or relative to any directory between the lcov file and the repo
# root (Vitest writes them relative to the package); all come out repo-relative.
#
# Exit: 0 report printed; 2 bad usage, an unreadable lcov file, or an unknown ref.
# POSIX sh + git + awk + sort.

set -u

usage() { echo "usage: sh coverage-summary.sh [--base <ref>] <lcov-file>..." >&2; exit 2; }

base=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
    --base=*) base="${1#--base=}"; shift ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ $# -ge 1 ] || usage

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "coverage-summary: not a git repository" >&2; exit 2; }
top="$(git rev-parse --show-toplevel)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t agent-ready)"
trap 'rm -rf "$tmp"' EXIT INT TERM

# ---------------------------------------------------------------------------
# 1. Parse every lcov file into  suite <TAB> repo-relative path <TAB> LF LH BRF BRH
# ---------------------------------------------------------------------------

cat > "$tmp/parse.awk" <<'AWK'
function canon(p) {
  gsub(/\\/, "/", p)
  if (p ~ /^[A-Za-z]:\//) p = "/" tolower(substr(p, 1, 1)) substr(p, 3)
  else if (p ~ /^\/[A-Za-z]\//) p = "/" tolower(substr(p, 2, 1)) substr(p, 3)
  return p
}
function exists(rel,   q) {
  q = top "/" rel
  if (q ~ /'/) return 0
  return system("test -f '" q "'") == 0
}
function resolve(p,   c, d, cand) {
  c = canon(p)
  if (c ~ /^\//) {
    if (index(tolower(c), tolower(ctop) "/") == 1) return substr(c, length(ctop) + 2)
    return c
  }
  sub(/^\.\//, "", c)
  d = ldir
  while (d != "") {
    cand = d "/" c
    if (exists(cand)) return cand
    if (d ~ /\//) sub(/\/[^\/]*$/, "", d); else d = ""
  }
  return c
}
function emit() {
  if (sf == "") return
  if (lf == "") { lf = da; lh = dah }
  if (brf == "") { brf = 0; brh = 0 }
  print suite "\t" resolve(sf) "\t" lf + 0 "\t" lh + 0 "\t" brf + 0 "\t" brh + 0
  sf = ""
}
{ sub(/\r$/, "") }
/^SF:/  { emit(); sf = substr($0, 4); lf = lh = brf = brh = ""; da = dah = 0; next }
/^DA:/  { split(substr($0, 4), a, ","); da++; if (a[2] + 0 > 0) dah++; next }
/^LF:/  { lf = substr($0, 4); next }
/^LH:/  { lh = substr($0, 4); next }
/^BRF:/ { brf = substr($0, 5); next }
/^BRH:/ { brh = substr($0, 5); next }
/^end_of_record/ { emit(); next }
END { emit() }
AWK

# The same canonical form as canon() in parse.awk: forward slashes, D:/ -> /d/.
canon() {
  printf '%s\n' "$1" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\):/|/\1/|' |
    awk '{ if ($0 ~ /^\/[A-Za-z]\//) $0 = "/" tolower(substr($0, 2, 1)) substr($0, 3); print }'
}
ctop="$(canon "$top")"

: > "$tmp/records"
: > "$tmp/suites"
for f in "$@"; do
  [ -f "$f" ] && [ -r "$f" ] || { echo "coverage-summary: cannot read $f" >&2; exit 2; }
  # The lcov file's directory, repo-relative: where relative SF: paths are tried
  # first. Asked of git, not derived from pwd — Git Bash's /tmp mount and symlinks
  # give pwd a different spelling of the same directory.
  ldir="$(cd "$(dirname "$f")" && git rev-parse --show-prefix 2>/dev/null)"
  ldir="${ldir%/}"
  printf '%s\n' "$f" >> "$tmp/suites"
  awk -v suite="$f" -v top="$top" -v ctop="$ctop" -v ldir="$ldir" -f "$tmp/parse.awk" "$f" >> "$tmp/records"
done

pct() { awk -v h="$1" -v t="$2" 'BEGIN { if (t + 0 == 0) print "—"; else printf "%.1f%% (%d/%d)\n", 100 * h / t, h, t }'; }

# ---------------------------------------------------------------------------
# 2. Totals, one row per lcov file
# ---------------------------------------------------------------------------

echo "## Coverage"
echo
echo "| Report | Files | Lines | Branches |"
echo "|---|---:|---:|---:|"
while IFS= read -r s; do
  # Word-splitting is the point: five numbers into $1..$5.
  # shellcheck disable=SC2046
  set -- $(awk -F '\t' -v s="$s" '$1 == s { n++; lf += $3; lh += $4; bf += $5; bh += $6 } END { print n + 0, lf + 0, lh + 0, bf + 0, bh + 0 }' "$tmp/records")
  echo "| \`$s\` | $1 | $(pct "$3" "$2") | $(pct "$5" "$4") |"
done < "$tmp/suites"

[ -n "$base" ] || exit 0

# ---------------------------------------------------------------------------
# 3. Changed files since the merge base with --base (plus uncommitted and untracked)
# ---------------------------------------------------------------------------

git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "coverage-summary: unknown ref $base" >&2; exit 2; }
mb="$(git merge-base "$base" HEAD)" || { echo "coverage-summary: no merge base with $base" >&2; exit 2; }
cd "$top" || exit 2
{ git diff --name-only --diff-filter=d "$mb"; git ls-files --others --exclude-standard; } | sort -u > "$tmp/changed"

echo
echo "### Changed files (since \`$base\`)"
echo
awk -F '\t' '
  function ext(p) { return match(p, /\.[^.\/]+$/) ? substr(p, RSTART) : "" }
  function istest(p) {
    return p ~ /(^|\/)(tests?|__tests__|spec|specs)\// || p ~ /\.(test|spec)\.[^\/]*$/ ||
           p ~ /_test\.[^\/]*$/ || p ~ /(^|\/)test_[^\/]*$/
  }
  function pct(h, t) { return t == 0 ? "—" : sprintf("%.1f%% (%d/%d)", 100 * h / t, h, t) }
  FNR == NR {
    exts[ext($2)] = 1
    # A file in several suites: keep the row with the most lines hit.
    if (!($2 in lf) || $4 > lh[$2]) { lf[$2] = $3; lh[$2] = $4; bf[$2] = $5; bh[$2] = $6 }
    next
  }
  {
    p = $0
    if (p in lf) {
      note = (lf[p] > 0 && lh[p] == 0) ? "**no test reaches it**" : ""
      row[++n] = "| `" p "` | " pct(lh[p], lf[p]) " | " pct(bh[p], bf[p]) " | " note " |"
    } else if (ext(p) != "" && (ext(p) in exts) && !istest(p)) {
      row[++n] = "| `" p "` | — | — | **not in report** |"; missing = 1
    }
  }
  END {
    if (n == 0) { print "No changed file is a source file the report covers."; exit }
    print "| File | Lines | Branches | |"
    print "|---|---:|---:|---|"
    for (i = 1; i <= n; i++) print row[i]
    if (missing) {
      print ""
      print "*not in report*: a changed source file the coverage report does not list. Many runners list only files a test loads, so usually no test reaches it; otherwise it is outside the coverage `include`."
    }
  }
' "$tmp/records" "$tmp/changed"

exit 0

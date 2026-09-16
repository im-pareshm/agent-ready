#!/bin/sh
# agent-ready — doc-drift.sh
#
# "I changed some code — which docs mention what I touched?"
#
# Extracts identifiers from a diff (function/class/type names, UPPER_SNAKE
# constants and env vars, route-like strings, JSON keys such as npm scripts,
# data-testid values, and the basenames of changed files) and lists every line
# in the repo's Markdown docs that mentions each one. It is a prompt to re-read,
# not a verdict: a mention may still be true.
#
# Usage:
#   sh scripts/doc-drift.sh              # uncommitted changes vs HEAD (+ untracked files)
#   sh scripts/doc-drift.sh HEAD~3       # everything since that commit
#   sh scripts/doc-drift.sh main..HEAD   # a range
#   sh scripts/doc-drift.sh --ids-only   # just print the identifiers it would look for
#
# Exit: 0 always (informational). POSIX sh + git + grep + awk + sort.

set -u

ids_only=0
range=""
for a in "$@"; do
  case "$a" in
    --ids-only) ids_only=1 ;;
    *) range="$a" ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "doc-drift: not a git repository" >&2; exit 0; }
top="$(git rev-parse --show-toplevel)"
cd "$top" || exit 0

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t agent-ready)"
trap 'rm -rf "$tmp"' EXIT INT TERM

# ---------------------------------------------------------------------------
# 1. Collect the diff text (changed lines only) and the changed file names
# ---------------------------------------------------------------------------
if [ -n "$range" ]; then
  if ! git diff --quiet "$range" -- >/dev/null 2>&1 && ! git diff "$range" -- >/dev/null 2>&1; then
    echo "doc-drift: '$range' is not a valid commit or range in this repository" >&2
    exit 0
  fi
  git diff "$range" -- . ':!*.md' ':!*.lock' ':!package-lock.json' >"$tmp/diff.txt" 2>/dev/null
  git diff --name-only "$range" -- . ':!*.md' >"$tmp/files.txt" 2>/dev/null
else
  git diff HEAD -- . ':!*.md' ':!*.lock' ':!package-lock.json' >"$tmp/diff.txt" 2>/dev/null
  git diff --name-only HEAD -- . ':!*.md' >"$tmp/files.txt" 2>/dev/null
  # Untracked files count as "added" in their entirety.
  git ls-files --others --exclude-standard | grep -vE '\.md$|(^|/)node_modules/' | while IFS= read -r f; do
    [ -f "$f" ] || continue
    printf '%s\n' "$f" >>"$tmp/files.txt"
    sed 's/^/+/' "$f" >>"$tmp/diff.txt" 2>/dev/null
  done
fi

grep -E '^[-+]' "$tmp/diff.txt" | grep -vE '^(\+\+\+|---) ' | cut -c2- >"$tmp/changed-lines.txt"
# Hunk headers carry the enclosing declaration ("@@ -62,17 +62,13 @@ export async
# function setCap(") — the only place a body-only change names its function.
grep -E '^@@ ' "$tmp/diff.txt" | sed -E 's/^@@[^@]*@@ ?//' | grep -E '.' >>"$tmp/changed-lines.txt"

# Basenames of changed files are useful only when unique in the repo — eight
# files called actions.ts make "actions" a noise word, not an identifier.
git ls-files | sed -E 's|.*/||' | sort | uniq -c | awk '$1 == 1 {print $2}' >"$tmp/unique-basenames.txt"

if [ ! -s "$tmp/changed-lines.txt" ] && [ ! -s "$tmp/files.txt" ]; then
  echo "doc-drift: no changes to inspect"
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Extract identifiers
# ---------------------------------------------------------------------------
{
  # declared names: function foo / def foo / func foo / fn foo / class Foo / const foo / type Foo …
  grep -oE '\b(function|def|func|fn|class|struct|enum|interface|type|const|let|var|export[[:space:]]+(default[[:space:]]+)?(function|const|class|type|interface))[[:space:]]+[A-Za-z_][A-Za-z0-9_]{3,}' "$tmp/changed-lines.txt" \
    | awk '{print $NF}'
  # UPPER_SNAKE constants and env vars (must contain an underscore)
  grep -oE '\b[A-Z][A-Z0-9]*_[A-Z0-9_]{2,}\b' "$tmp/changed-lines.txt"
  # route-like strings: "/known", '/api/auth'
  grep -oE "[\"'\`]/[a-z][a-z0-9/_:-]{2,}[\"'\`]" "$tmp/changed-lines.txt" | tr -d "\"'\`"
  # JSON/YAML keys of 4+ chars (npm scripts, config keys)
  grep -oE '^[[:space:]]*"[a-z][a-z0-9:_-]{3,}"[[:space:]]*:' "$tmp/changed-lines.txt" | tr -d '" :'
  # data-testid / id hooks
  grep -oE 'data-testid=[\"'"'"'`][^\"'"'"'`]{3,}[\"'"'"'`]' "$tmp/changed-lines.txt" | sed -E 's/^data-testid=.//; s/.$//' | grep -vE '\$\{'
  # basenames of changed files (only those unique in the repo), with and without extension
  sed -E 's|.*/||' "$tmp/files.txt" | grep -xF -f "$tmp/unique-basenames.txt" | while IFS= read -r b; do
    printf '%s\n' "$b"
    printf '%s\n' "$b" | sed -E 's|\.[A-Za-z0-9]+$||'
  done
} | grep -E '.{4,}' | sort -u >"$tmp/ids-raw.txt"

# Stoplist: words that appear in every doc and mean nothing on their own.
cat >"$tmp/stop.txt" <<'EOF'
true
false
null
undefined
return
const
import
export
default
function
async
await
string
number
boolean
object
error
class
interface
type
this
that
with
from
main
master
test
tests
index
page
pages
README
LICENSE
CHANGELOG
props
state
value
values
name
data
item
items
user
users
list
form
input
button
description
next
prev
today
shared
fields
icons
label
labels
title
status
active
month
year
date
amount
total
count
result
results
config
options
option
params
query
client
server
utils
helpers
types
components
hooks
styles
actions
handler
context
layout
route
routes
EOF

grep -vxF -f "$tmp/stop.txt" "$tmp/ids-raw.txt" >"$tmp/ids.txt"

if [ "$ids_only" -eq 1 ]; then
  cat "$tmp/ids.txt"
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. Look each identifier up in the docs
# ---------------------------------------------------------------------------
git ls-files -co --exclude-standard | grep -E '\.md$' | grep -vE '(^|/)(node_modules|vendor|dist|build)/' >"$tmp/docs.txt"

total_ids="$(wc -l <"$tmp/ids.txt" | tr -d ' ')"
hits=0
echo "doc-drift: $total_ids identifiers from the diff; searching $(wc -l <"$tmp/docs.txt" | tr -d ' ') Markdown files"
echo "------------------------------------------------------------------"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  # word-boundary match, fixed string, case-sensitive
  out="$(xargs grep -nwF -- "$id" <"$tmp/docs.txt" 2>/dev/null)"
  [ -n "$out" ] || continue
  hits=$((hits + 1))
  printf '\n## %s\n' "$id"
  printf '%s\n' "$out" | cut -c1-180 | head -12
  n="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
  [ "$n" -gt 12 ] && echo "   … ($n lines total)"
done <"$tmp/ids.txt"

echo
echo "------------------------------------------------------------------"
if [ "$hits" -eq 0 ]; then
  echo "No doc mentions any identifier in this change."
  echo "Still check the ownership table in AGENTS.md: a doc can describe behaviour"
  echo "without naming the code that implements it."
else
  echo "$hits of $total_ids identifiers are mentioned in docs. Re-read each passage and"
  echo "decide whether it still holds. Fix in the same commit; don't leave a note."
fi
exit 0

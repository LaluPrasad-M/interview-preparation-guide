#!/bin/sh
# Blocks leftover merge conflict markers. A stray marker silently corrupts a note,
# and it is easy to miss when resolving a conflict on a phone.
#
# Usage:
#   scripts/check-conflicts.sh           staged added lines only (what the hook runs)
#   scripts/check-conflicts.sh --all     every file in the working tree
set -eu

PAT='^(<<<<<<<|>>>>>>>) '
MSG='merge conflict marker'

if [ "${1:-}" = "--all" ]; then
  out=$(git ls-files --cached --others --exclude-standard '*.md' | while read -r f; do
    [ -f "$f" ] || continue
    grep -nE "$PAT" "$f" 2>/dev/null | while IFS=: read -r n _; do
      printf '  %s:%s  %s\n' "$f" "$n" "$MSG"
    done
  done)
else
  out=$(git diff --cached --unified=0 --diff-filter=ACM -- '*.md' | awk -v msg="$MSG" '
    /^\+\+\+ b\// { file = substr($0, 7); next }
    file == "" { next }
    /^@@/ { if (match($0, /\+[0-9]+/)) ln = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
    /^\+/ {
      line = substr($0, 2)
      if (line ~ /^(<<<<<<<|>>>>>>>) /) printf "  %s:%d  %s\n", file, ln, msg
      ln++
    }
  ')
fi

if [ -n "$out" ]; then
  printf '\nConflict marker check failed:\n%s\n' "$out" >&2
  printf '\nFix: finish the merge, then delete every marker line.\n\n' >&2
  exit 1
fi

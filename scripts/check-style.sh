#!/bin/sh
# Style gate: no em dash (U+2014) and no en dash (U+2013) anywhere in the repo.
# Ported from git-automation-v2/scripts/check-style.mjs, minus its 120-column rule
# (that script exempts .md files from length anyway, and this repo is all .md).
#
# The two glyphs are built from byte escapes below, so this file stays free of the
# very characters it bans.
#
# Usage:
#   scripts/check-style.sh           staged added lines only (what the hook runs)
#   scripts/check-style.sh --all     every file in the working tree
#   scripts/check-style.sh PATH...   those files, tracked or not
#
# Escape hatch: a line containing "style-ignore" is skipped.
set -eu

EM=$(printf '\342\200\224')
EN=$(printf '\342\200\223')
PAT="$EM|$EN"
MSG='em/en dash (use plain punctuation)'

found=0
report() {
  found=1
  printf '  %s\n' "$1"
}

scan_file() {
  [ -f "$1" ] || return 0
  grep -nE "$PAT" "$1" 2>/dev/null | grep -v 'style-ignore' | while IFS=: read -r n _; do
    printf '  %s:%s  %s\n' "$1" "$n" "$MSG"
  done
}

case "${1:-}" in
  --all)
    # Tracked plus untracked-but-not-ignored, so a new note is checked before
    # it is ever staged.
    out=$(git ls-files --cached --others --exclude-standard | while read -r f; do scan_file "$f"; done)
    ;;
  '')
    # Added lines of the staged diff, with their line number in the new file.
    out=$(git diff --cached --unified=0 --diff-filter=ACM | awk -v pat="$PAT" -v msg="$MSG" '
      /^\+\+\+ b\// { file = substr($0, 7); next }
      file == "" { next }
      /^@@/ { if (match($0, /\+[0-9]+/)) ln = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
      /^\+/ {
        line = substr($0, 2)
        if (line ~ pat && line !~ /style-ignore/) printf "  %s:%d  %s\n", file, ln, msg
        ln++
      }
    ')
    ;;
  *)
    out=$(for p in "$@"; do
      if [ -d "$p" ]; then
        find "$p" -type f | while read -r f; do scan_file "$f"; done
      else
        scan_file "$p"
      fi
    done)
    ;;
esac

if [ -n "$out" ]; then
  printf '\nStyle check failed:\n%s\n' "$out" >&2
  printf '\nFix: replace with a comma, semicolon, colon, period, or parentheses, or rewrite the sentence.\n\n' >&2
  exit 1
fi

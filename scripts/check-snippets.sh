#!/bin/sh
# Snippet gate: every fenced code block that existed at BASELINE must still
# appear somewhere under vault/, whitespace normalised. Blocks move between
# notes freely; they just may not disappear.
#
# Usage: scripts/check-snippets.sh <baseline-ref> [path-prefix]
set -eu

BASE=$1
PREFIX=${2:-vault/}
ROOT=$(git rev-parse --show-toplevel)

NOW=$(mktemp); OLD=$(mktemp)
trap 'rm -f "$NOW" "$OLD"' EXIT

# Fingerprint every code line: strip leading and trailing space, drop blanks,
# drop fence markers. A block survives if all of its fingerprints survive.
fingerprints() {
  awk '/^ *```/ { fence = !fence; next } fence { gsub(/^[ \t]+|[ \t]+$/, ""); if (length($0) > 3) print }'
}

git ls-files "$PREFIX" | grep '\.md$' | while read -r f; do
  fingerprints < "$ROOT/$f"
done | sort -u > "$NOW"

git ls-tree -r --name-only "$BASE" "$PREFIX" | grep '\.md$' | while read -r f; do
  git show "$BASE:$f" | fingerprints | sed "s|^|$f\t|"
done | sort -u > "$OLD"

missing=$(awk -F'\t' 'NR == FNR { now[$0] = 1; next } !($2 in now) { print "  " $1 ": " $2 }' "$NOW" "$OLD")

if [ -n "$missing" ]; then
  printf '\nMISSING SNIPPET lines, present at %s and gone now:\n%s\n' "$BASE" "$missing" >&2
  exit 1
fi

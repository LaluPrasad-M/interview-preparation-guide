#!/bin/sh
# Link gate: every [[wikilink]] must resolve to a .md file somewhere in vault/.
# Links inside fenced code blocks and inline code spans are skipped, because
# `[[Prototype]]` is JavaScript spec notation, not a link.
#
# Usage:
#   scripts/check-links.sh           vault/, the whole thing
#   scripts/check-links.sh PATH...   those files or directories
set -eu

ROOT=$(git rev-parse --show-toplevel)
INDEX=$(mktemp)
trap 'rm -f "$INDEX"' EXIT

# One line per note basename, so resolution is a lookup rather than a find per link.
# Index roots are vault/ plus the directory of each given path (not the bare file),
# so a link between sibling fixture notes outside vault/ still resolves.
index_roots="$ROOT/vault"
for p in "$@"; do
  if [ -d "$p" ]; then
    index_roots="$index_roots $p"
  else
    index_roots="$index_roots $(dirname "$p")"
  fi
done
find $index_roots -name '*.md' 2>/dev/null | while read -r f; do
  basename "$f" .md
done | sort -u > "$INDEX"

scan() {
  awk -v index_file="$INDEX" -v path="$1" '
    BEGIN { while ((getline n < index_file) > 0) known[n] = 1 }
    /^ *```/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)          # drop inline code spans
      while (match(line, /\[\[[^]]+\]\]/)) {
        raw = substr(line, RSTART + 2, RLENGTH - 4)
        line = substr(line, RSTART + RLENGTH)
        sub(/\|.*/, "", raw)             # [[note|alias]]
        sub(/#.*/, "", raw)              # [[note#heading]]
        if (raw != "" && !(raw in known))
          printf "  %s:%d  unresolved link: %s\n", path, NR, raw
      }
    }
  ' "$1"
}

targets=${*:-"$ROOT/vault"}
out=$(for p in $targets; do
  if [ -d "$p" ]; then
    find "$p" -name '*.md' | while read -r f; do scan "$f"; done
  else
    scan "$p"
  fi
done)

if [ -n "$out" ]; then
  printf '\nLink check failed:\n%s\n' "$out" >&2
  printf '\nFix: correct the link, or create the note it points at.\n\n' >&2
  exit 1
fi

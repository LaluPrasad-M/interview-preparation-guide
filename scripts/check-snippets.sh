#!/bin/sh
# Snippet gate: every fenced code block that existed at BASELINE must still
# appear somewhere under vault/, whitespace normalised. A block is matched as
# a whole first, since blocks move and reorder between notes freely; only
# when the whole block cannot be found does the check fall back to individual
# lines, so a legitimate split is reported instead of failing the run.
#
# Usage: scripts/check-snippets.sh <baseline-ref> [path-prefix]
set -eu

BASE=$1
PREFIX=${2:-vault/}
ROOT=$(git rev-parse --show-toplevel)

NOWLINES=$(mktemp); NOWBLOCKS=$(mktemp)
trap 'rm -f "$NOWLINES" "$NOWBLOCKS"' EXIT

# Every fenced code block's lines, trimmed and blanks dropped, one block per
# paragraph (blocks are separated by a blank output line). No length filter:
# a one-line block counts. Tolerates indented fences. Reads stdin.
#
# Callout markers are stripped before anything else, because wrapping a code
# block in a "> [!example]-" callout prefixes every line with "> ". That is a
# presentation change, not a code change, and without this the whole block
# reads as missing.
blocks() {
  awk '
    { sub(/^[ \t]*>[ \t]?/, "") }
    /^ *```/ {
      if (fence) {
        if (n > 0) { for (i = 1; i <= n; i++) print lines[i]; print "" }
        fence = 0
      } else {
        fence = 1; n = 0; delete lines
      }
      next
    }
    fence {
      l = $0
      gsub(/^[ \t]+|[ \t]+$/, "", l)
      if (length(l) > 0) { n++; lines[n] = l }
    }
  '
}

hash_block() { shasum -a 1 | cut -d' ' -f1; }

# Collapse a blocks() stream into one fingerprint per block.
block_hashes() {
  buf=
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ]; then
      if [ -z "$buf" ]; then buf=$line; else buf="$buf
$line"; fi
    else
      [ -n "$buf" ] && printf '%s\n' "$buf" | hash_block
      buf=
    fi
  done
  [ -n "$buf" ] && printf '%s\n' "$buf" | hash_block
}

# Every block from BASE's version of $f: check whole first, then per line.
check_blocks() {
  f=$1
  buf=
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ]; then
      if [ -z "$buf" ]; then buf=$line; else buf="$buf
$line"; fi
      continue
    fi
    [ -n "$buf" ] || continue
    hash=$(printf '%s\n' "$buf" | hash_block)
    if grep -qxF "$hash" "$NOWBLOCKS"; then
      buf=
      continue
    fi
    first=$(printf '%s\n' "$buf" | head -n1)
    missing=$(printf '%s\n' "$buf" | while IFS= read -r bl; do
      grep -qxF "$bl" "$NOWLINES" || printf '%s\n' "$bl"
    done)
    if [ -z "$missing" ]; then
      printf 'SPLIT BLOCK  %s: %s\n' "$f" "$first"
    else
      printf '%s\n' "$missing" | while IFS= read -r bl; do
        printf 'MISSING SNIPPET  %s: %s\n' "$f" "$bl"
      done
    fi
    buf=
  done
}

# Current code lines, for the line-level fallback.
git ls-files "$PREFIX" | grep '\.md$' | while read -r f; do
  blocks < "$ROOT/$f"
done | grep -v '^$' | sort -u > "$NOWLINES"

# Current block fingerprints, for the whole-block check.
git ls-files "$PREFIX" | grep '\.md$' | while read -r f; do
  blocks < "$ROOT/$f"
done | block_hashes | sort -u > "$NOWBLOCKS"

report=$(
  git ls-tree -r --name-only "$BASE" "$PREFIX" | grep '\.md$' | while read -r f; do
    git show "$BASE:$f" | blocks | check_blocks "$f"
  done
)

if [ -n "$report" ]; then
  if printf '%s\n' "$report" | grep -q '^MISSING SNIPPET'; then
    printf '\nMISSING SNIPPET lines, present at %s and gone now:\n%s\n' "$BASE" "$report" >&2
    exit 1
  fi
  printf '\n%s\n' "$report"
fi

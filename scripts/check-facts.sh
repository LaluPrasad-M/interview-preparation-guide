#!/bin/sh
# Fact gate: the hard facts that existed at BASELINE must still exist somewhere
# under vault/. A rewrite is allowed to reword any sentence, so prose cannot be
# diffed. Numbers, versions and acronyms are not prose: if one disappears, the
# rewrite lost a fact rather than tightening a sentence.
#
# check-snippets.sh covers code. This covers everything a rewrite is most
# likely to drop while sounding fine: a version string, a latency figure, a
# percentage, a named standard.
#
# Usage: scripts/check-facts.sh <baseline-ref>
set -eu

BASE=$1
ROOT=$(git rev-parse --show-toplevel)

NOW=$(mktemp); OLD=$(mktemp)
trap 'rm -f "$NOW" "$OLD"' EXIT

# A fact is one of:
#   a version or dotted number   v22.16.0, 16384, 2.0
#   a number with a unit         500 ms, 10,000 QPS, 64 bit, 20 percent
#   a percentage                 15%
#   an acronym of 3 or more caps WAL, MVCC, HMAC, OIDC
facts() {
  # Unwrap wikilinks first. Linking a unit turns "1,000,000 QPS" into
  # "1,000,000 [[qps|QPS]]", which splits the number from its unit and reads as
  # a lost fact. [[a|b]] becomes b, [[a]] becomes a.
  sed -e 's/\[\[[^]|]*|\([^]]*\)\]\]/\1/g' -e 's/\[\[\([^]]*\)\]\]/\1/g' "$@" 2>/dev/null \
    | grep -ohE 'v?[0-9]+\.[0-9]+(\.[0-9]+)?|[0-9][0-9,]* ?(ms|s|MB|GB|KB|TB|QPS|RPS|percent|%|bytes|bit|bits)\b|\b[A-Z]{3,}\b' \
    | sed 's/[[:space:]]\{1,\}/ /g' | sort -u
}

find "$ROOT/vault" -name '*.md' -exec cat {} + > "$NOW.raw"
facts "$NOW.raw" > "$NOW"

tmpdir=$(mktemp -d)
git ls-tree -r --name-only "$BASE" vault | grep '\.md$' | while read -r f; do
  git show "$BASE:$f"
done > "$tmpdir/old.raw"
facts "$tmpdir/old.raw" > "$OLD"
rm -rf "$tmpdir"

missing=$(comm -23 "$OLD" "$NOW")

if [ -n "$missing" ]; then
  printf '\nFACTS present at %s and gone now:\n' "$BASE" >&2
  printf '%s\n' "$missing" | sed 's/^/  /' >&2
  printf '\nEach one is a number, version or acronym a rewrite dropped.\n' >&2
  printf 'Find where it lived (git grep it at the baseline) and put it back.\n\n' >&2
  exit 1
fi

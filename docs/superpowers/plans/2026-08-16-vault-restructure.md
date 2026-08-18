# Vault Restructure and Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move 217 notes into a folder tree you can guess, add a `Dictionary/` where every jargon word is explained exactly once, and rewrite every note to the six rules in `STYLE.md` without losing a single sentence of content.

**Architecture:** Six phases, each ending at a vault you could stop and use. Structure moves before words change, so the tree can be rejected cheaply. Content changes are guarded by two automated checkers (links, code snippets) and by a writer agent followed by an independent reviewer agent per area.

**Tech Stack:** Markdown, Obsidian wikilinks, POSIX shell checkers under `scripts/`, git.

**Spec:** `docs/superpowers/specs/2026-08-16-vault-restructure-design.md`

---

## Global Constraints

- `STYLE.md` rules 1 to 6 govern every word written. Where this plan and a rule disagree, the rule wins.
- No em dash (U+2014) or en dash (U+2013) in any file, including this plan and the scripts. `scripts/check-style.sh` enforces it.
- Note length cap: around 250 lines. Paragraph cap: 3 lines. Every H2 sits between `---` dividers. Every note opens with `> [!tldr]`.
- Callout types are exactly five: `tldr`, `tip`, `warning`, `example`, `question`.
- Wikilinks are bare (`[[binary-search]]`), never folder-prefixed. Filenames stay unique across the whole vault, because the vault uses shortest-path links.
- Technical vocabulary is mandatory (Rule 4). A rewrite that removes `throttling`, `idempotent`, `backpressure`, `MVCC` and similar in the name of simplicity is a failed rewrite.
- A term is explained in exactly one file (Rule 5). Notes link to it, they do not re-explain it.
- Zero content loss. Every claim, example, number, table row and code block in the original survives into some note, or the reviewer reports it as lost.
- `_inbox/` is never committed. Vymo material stays flagged with its existing warning callout.
- Commit after every task. Never force-push `main`.

---

## Task 1: The link checker

Nothing else is safe until a broken wikilink is detectable. 224 unique link targets are about to move.

**Files:**
- Create: `scripts/check-links.sh`
- Create: `tests/fixtures/links/good.md`, `tests/fixtures/links/bad.md`, `tests/fixtures/links/code-span.md`
- Modify: `.githooks/pre-commit`

**Interfaces:**
- Produces: `scripts/check-links.sh [--all|PATH...]`, exit 0 when every wikilink resolves, exit 1 with `file:line  unresolved link: NAME` lines otherwise. Every later task runs this.

- [ ] **Step 1: Write the failing test fixtures**

```bash
mkdir -p tests/fixtures/links
printf '# Good\n\nSee [[target-note]] and [[target-note|an alias]] and [[target-note#a-heading]].\n' > tests/fixtures/links/good.md
printf '# Target Note\n\nContent.\n' > tests/fixtures/links/target-note.md
printf '# Bad\n\nSee [[note-that-does-not-exist]].\n' > tests/fixtures/links/bad.md
printf '# Code Span\n\nThe engine uses `[[Prototype]]` internally.\n\n```js\nconst x = "[[also-not-a-link]]";\n```\n' > tests/fixtures/links/code-span.md
```

- [ ] **Step 2: Run the checker and watch it fail because it does not exist**

Run: `bash scripts/check-links.sh tests/fixtures/links/bad.md`
Expected: FAIL with "No such file or directory"

- [ ] **Step 3: Write the checker**

```sh
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
find "$ROOT/vault" "$@" -name '*.md' 2>/dev/null | while read -r f; do
  basename "$f" .md
done | sort -u > "$INDEX"

scan() {
  awk -v index_file="$INDEX" -v path="$1" '
    BEGIN { while ((getline n < index_file) > 0) known[n] = 1 }
    /^```/ { fence = !fence; next }
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
```

- [ ] **Step 4: Run the three fixtures and verify each verdict**

```bash
chmod +x scripts/check-links.sh
bash scripts/check-links.sh tests/fixtures/links/good.md      # expect exit 0
bash scripts/check-links.sh tests/fixtures/links/code-span.md # expect exit 0, no Prototype complaint
bash scripts/check-links.sh tests/fixtures/links/bad.md       # expect exit 1, names note-that-does-not-exist
```

Expected: PASS, PASS, FAIL naming `note-that-does-not-exist`.

- [ ] **Step 5: Run it against the real vault to get the baseline**

Run: `bash scripts/check-links.sh`
Expected: exit 0. If anything is reported, it is a genuinely broken link that predates this work. Fix it now and note it in the commit message.

- [ ] **Step 6: Wire it into the pre-commit hook**

Add to `.githooks/pre-commit`, after the existing style and conflict checks:

```sh
"$(git rev-parse --show-toplevel)/scripts/check-links.sh" || exit 1
```

- [ ] **Step 7: Commit**

```bash
git add scripts/check-links.sh tests/fixtures/links .githooks/pre-commit
git commit -m "tooling: add wikilink resolution check"
```

---

## Task 2: The snippet survival checker

The rewrite's real risk is a code block quietly vanishing. This makes that detectable instead of hoped for.

**Files:**
- Create: `scripts/check-snippets.sh`

**Interfaces:**
- Consumes: a git ref holding the pre-rewrite state.
- Produces: `scripts/check-snippets.sh <baseline-ref> [path-prefix]`, printing `MISSING SNIPPET` lines for any fenced code block present at the baseline whose body no longer appears anywhere in `vault/`.

- [ ] **Step 1: Create the baseline tag**

```bash
git tag pre-rewrite
git rev-parse pre-rewrite
```

- [ ] **Step 2: Write the checker**

```sh
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
```

- [ ] **Step 3: Run it against an unchanged tree and verify it passes**

Run: `bash scripts/check-snippets.sh pre-rewrite`
Expected: exit 0, because nothing has changed yet.

- [ ] **Step 4: Prove it catches a deletion**

```bash
git stash list > /dev/null
sed -i '' '/^const /d' vault/Node/snippets/arrays.md
bash scripts/check-snippets.sh pre-rewrite   # expect exit 1 listing the removed lines
git checkout vault/Node/snippets/arrays.md
```

Expected: FAIL listing removed lines, then a clean tree again.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-snippets.sh
git commit -m "tooling: add code snippet survival check"
```

---

## Task 3: Rewrite CONTRIBUTING.md and README.md

Docs describe the new tree before the tree exists, so every later task has one place to follow.

**Files:**
- Modify: `CONTRIBUTING.md` (the "Where a note belongs" section, currently lines 15 to 49)
- Modify: `README.md` (the "Layout" tree, currently lines 7 to 23, and the "Where things are" table)

**Interfaces:**
- Produces: the authoritative folder table that Task 4 moves files against.

- [ ] **Step 1: Replace the folder table in CONTRIBUTING.md**

New table, replacing the old one wholesale:

```markdown
| Folder | Holds |
| --- | --- |
| `Dictionary/` | one entry per jargon word, flat, filename is the spoken form |
| `DSA/` | method notes at the root, then `arrays/`, `binary-search/`, `trees/`, `graphs/`, `dp/`, `backtracking/`, `greedy/`, `data-structures/` |
| `JavaScript/` | `language/`, `typescript/`, `node/` with `node/server/` and `node/puzzles/`, `snippets/` |
| `React/` | fundamentals and the live coding components |
| `Design/` | `object-design/`, `patterns/`, `system-design/`, `scaling/`, `worked/` with `worked/lld/`, `worked/systems/`, `worked/real/` |
| `Databases/` | `sql/`, `mongodb/`, `redis/`, `modelling/`, `operations/`, `change-data/` |
| `Kafka/` | flat, one note per mechanic |
| `Backend/` | API design, idempotency, status codes, realtime transports |
| `Security/` | authentication, authorization, hardening, encryption, JWT, HMAC, XSS |
| `Cloud/` | `aws/`, `kubernetes/`, `cicd/` |
| `Operations/` | what breaks in production and where to look first |
| `AI/` | working with models as infrastructure |
| `Interviews/` | `rounds/`, `practice/`, experiences, checklists |
| `assets/` | images referenced from notes |
```

- [ ] **Step 2: Add the two new placement rules to CONTRIBUTING.md**

Under the table, replacing the old `DSA/` against `DSA/patterns/` judgment-call paragraph:

```markdown
The judgment calls, and how to settle them:

**A thing against a move you make.** In `DSA/`, if you would describe it as "a thing" it goes in the structure folder, if you would describe it as "a move you make" it goes in the pattern folder.

**A concept against a worked design.** `Backend/idempotency` is the concept. `Design/worked/systems/ai-tool-idempotency` is a system that applies it. If it has requirements and a diagram, it is a worked design.

**A note against a dictionary entry.** If it needs more than a short definition and a pointer, it is a note. A `Dictionary/` entry never explains a topic that has its own note; it links to that note instead.

Every index note carries a `Filed elsewhere` table naming what you might reasonably expect in that folder and where it actually went. Adding a note that could plausibly live in two folders means adding a row to the loser's index.
```

- [ ] **Step 3: Update the README layout tree**

```text
placement-notes/
  vault/            <- open this one in Obsidian
    _index.md       the map, every area links from here
    Dictionary/     every jargon word, explained once
    DSA/  JavaScript/  React/  Design/  Databases/  Kafka/
    Backend/  Security/  Cloud/  Operations/  AI/  Interviews/
    assets/         images referenced from notes
    .obsidian/      vault settings, tracked
  _inbox/           raw source material, local only, never committed
  README.md  CONTRIBUTING.md  STYLE.md
  scripts/  .githooks/  docs/
```

- [ ] **Step 4: Add the two new scripts to the README "Where things are" table**

```markdown
| [scripts/check-links.sh](scripts/check-links.sh) | every wikilink resolves, run by the pre-commit hook |
| [scripts/check-snippets.sh](scripts/check-snippets.sh) | no code block silently disappears during a rewrite |
```

- [ ] **Step 5: Verify both docs pass the style gate**

```bash
bash scripts/check-style.sh CONTRIBUTING.md README.md
```

Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add CONTRIBUTING.md README.md
git commit -m "docs: describe the new vault tree before moving anything"
```

---

## Task 4: Move every file, phase 1, structure only

Pure `git mv` plus link repair. Not one word of note content changes, so the diff is reviewable and the tree can be rejected for the cost of one revert.

**Files:**
- Move: all 217 notes per the spec's "Where every file goes" tables
- Modify: every note containing a wikilink whose target filename changed (only renames need link edits, moves do not, because links are bare)

**Interfaces:**
- Consumes: the folder table from Task 3.
- Produces: the new tree, which Tasks 5 through 9 operate inside.

- [ ] **Step 1: Create the folders**

```bash
cd vault
mkdir -p Dictionary DSA/data-structures JavaScript/language JavaScript/typescript \
  JavaScript/node/server JavaScript/node/puzzles JavaScript/snippets \
  Design/object-design Design/patterns Design/system-design Design/scaling \
  Design/worked/lld Design/worked/systems Design/worked/real \
  Databases/modelling Databases/operations Databases/change-data \
  Cloud/aws Cloud/kubernetes Cloud/cicd Operations Interviews/rounds Interviews/practice
```

- [ ] **Step 2: Move JavaScript, DSA and React**

```bash
git mv Node/javascript/* JavaScript/language/
git mv Node/typescript/* JavaScript/typescript/
git mv Node/snippets/server/* JavaScript/node/server/
git mv Node/runtime/puzzles-promises.md Node/runtime/puzzles-scheduling.md JavaScript/node/puzzles/
git mv Node/runtime/* JavaScript/node/
git mv Node/snippets/* JavaScript/snippets/
git mv Node/node.md JavaScript/javascript.md
git mv DSA/lru-and-min-stack.md DSA/data-structures/
git mv DSA/linked-list/reverse-a-list.md DSA/data-structures/
git mv DSA/problem-lists.md Interviews/practice/dsa-problems.md
rmdir Node/javascript Node/typescript Node/snippets/server Node/runtime Node/snippets Node DSA/linked-list
```

- [ ] **Step 3: Move Design, the big one**

```bash
git mv OOP/four-pillars.md OOP/solid.md OOP/solid-js-vs-ts.md OOP/abstract-classes.md \
  OOP/access-modifiers.md OOP/overloading-vs-overriding.md OOP/js-vs-ts-compilation.md \
  Design/object-design/
git mv LLD/abstraction-and-dependency-injection.md LLD/inheritance-vs-composition.md Design/object-design/
git mv LLD/six-step-framework.md Design/object-design/how-to-do-an-lld-round.md
git mv LLD/patterns/* Design/patterns/
git mv LLD/checkout-worked-example.md LLD/ride-booking-worked-example.md Design/worked/lld/
git mv LLD/machine-coding-list.md Interviews/practice/machine-coding.md
git mv System-Design/concepts/cross-site-scripting.md Security/
git mv System-Design/concepts/* Design/system-design/
git mv System-Design/scaling/* Design/scaling/
git mv System-Design/terms/* Dictionary/
git mv System-Design/worked-designs/* Design/worked/systems/
git mv System-Design/case-studies/jio-cinema.md Design/worked/real/
git mv System-Design/worked-examples/vymo-websales Design/worked/real/vymo-websales
git mv System-Design/system-design.md Design/design.md
# The two old indexes are kept, not deleted, because step 7 folds their tables
# into design.md. Deleting them here would put content only in git history.
git mv OOP/oop.md Design/_merge-from-oop.md
git mv LLD/lld.md Design/_merge-from-lld.md
rmdir -p LLD/patterns OOP System-Design/concepts System-Design/scaling System-Design/terms \
  System-Design/worked-designs System-Design/case-studies System-Design/worked-examples 2>/dev/null || true
```

- [ ] **Step 4: Move Databases, Cloud, Operations, Interviews**

```bash
git mv Databases/concepts/normalization.md Databases/concepts/schema-design-questions.md \
  Databases/concepts/food-delivery-schema.md Databases/concepts/choosing-a-datastore.md \
  Databases/concepts/sql-vs-mongodb.md Databases/modelling/
git mv Databases/concepts/zero-downtime-migration.md Databases/concepts/locking-strategies.md \
  Databases/concepts/replication-partitioning-sharding.md Databases/concepts/replication-lag.md \
  Databases/operations/
git mv Databases/concepts/change-data-capture.md Databases/concepts/inbox-pattern.md \
  Databases/concepts/out-of-order-events.md Databases/change-data/
git mv Databases/concepts/clickhouse.md Databases/
rmdir Databases/concepts

git mv AWS/compute AWS/s3 Cloud/aws/
git mv AWS/kubernetes/* Cloud/kubernetes/
git mv Deployment/kubernetes-docker-cicd.md Cloud/kubernetes/
git mv AWS/deployment/* Cloud/cicd/
git mv Deployment/github-actions.md Cloud/cicd/
git mv AWS/aws.md Cloud/cloud.md
git mv Deployment/deployment.md Cloud/_merge-from-deployment.md
rmdir -p AWS/kubernetes AWS/deployment AWS Deployment 2>/dev/null || true

git mv Incident-Management/categories.md Operations/what-breaks-in-production.md
git mv Incident-Management/incident-management.md Operations/operations.md
rmdir Incident-Management
git mv Interviews/sprint-list.md Interviews/practice/sprint-list.md
```

- [ ] **Step 5: Repair links broken by the four renames**

Only renamed files need link edits. Bare wikilinks survive a move.

```bash
cd vault
grep -rln "\[\[six-step-framework\]\]" --include="*.md" . | xargs sed -i '' 's/\[\[six-step-framework\]\]/[[how-to-do-an-lld-round]]/g'
grep -rln "\[\[problem-lists\]\]"      --include="*.md" . | xargs sed -i '' 's/\[\[problem-lists\]\]/[[dsa-problems]]/g'
grep -rln "\[\[machine-coding-list\]\]" --include="*.md" . | xargs sed -i '' 's/\[\[machine-coding-list\]\]/[[machine-coding]]/g'
grep -rln "\[\[categories\]\]"          --include="*.md" . | xargs sed -i '' 's/\[\[categories\]\]/[[what-breaks-in-production]]/g'
for old in node aws lld oop system-design deployment incident-management; do
  grep -rn "\[\[$old\]\]" --include="*.md" . || true
done
```

The loop prints every link to a removed or renamed index. Repoint each by hand: `[[node]]` becomes `[[javascript]]`, `[[aws]]` becomes `[[cloud]]`, `[[lld]]` and `[[oop]]` and `[[system-design]]` all become `[[design]]`, `[[deployment]]` becomes `[[cloud]]`, `[[incident-management]]` becomes `[[operations]]`.

- [ ] **Step 6: Verify no content changed and no link broke**

```bash
git diff --cached --stat            # every line should be a rename, plus the link edits from step 5
bash scripts/check-links.sh         # expect exit 0
bash scripts/check-snippets.sh pre-rewrite   # expect exit 0, nothing rewritten yet
find vault -name '*.md' -exec basename {} \; | sort | uniq -d   # expect empty, filenames stay unique
```

Expected: all four clean. The last one matters because shortest-path links break the moment two notes share a filename.

- [ ] **Step 7: Write the 13 area indexes**

One per top folder, each following Rule 6: `[!tldr]`, a table per subfolder with `Note` and `Covers` columns, and a `Filed elsewhere` table. Update `vault/_index.md` to point at the 13 new area indexes and nothing else.

`Design/design.md` folds in every row from `_merge-from-oop.md` and `_merge-from-lld.md`, and `Cloud/cloud.md` folds in `_merge-from-deployment.md`. Delete the three `_merge-from-*` files only after their tables are in the new index:

```bash
grep -c "\[\[" vault/Design/_merge-from-oop.md vault/Design/_merge-from-lld.md vault/Cloud/_merge-from-deployment.md
# every one of those links must appear in the new index before you delete the file
rm vault/Design/_merge-from-*.md vault/Cloud/_merge-from-deployment.md
```

Every index needs its `Filed elsewhere` rows to cover the moves that will surprise someone:

| Index | Must redirect |
| --- | --- |
| `Security/security.md` | `s3-security` to `Cloud/aws/s3/`, `webhook-signatures` stays, `oauth-token-lifecycle` to `Design/worked/systems/` |
| `Backend/backend.md` | `ai-tool-idempotency` and the webhook designs to `Design/worked/systems/` |
| `Databases/databases.md` | `read-scaling` and `write-scaling` to `Design/scaling/`, `caching-problems` stays in `redis/` |
| `Kafka/kafka.md` | `inbox-pattern` and `change-data-capture` to `Databases/change-data/`, `websocket-bridge` stays |
| `JavaScript/javascript.md` | `patterns-js-vs-ts` and `js-vs-ts-compilation` to `Design/object-design/` |
| `Design/design.md` | `idempotency` to `Backend/`, `jwt` to `Security/` |
| `Cloud/cloud.md` | `github-actions` now in `cicd/`, `kubernetes-docker-cicd` now in `kubernetes/` |
| `Operations/operations.md` | Kafka lag to `Kafka/`, `service-layer` failure modes to `Design/scaling/` |
| `Interviews/interviews.md` | `how-to-solve` to `DSA/`, `how-to-do-an-lld-round` to `Design/object-design/` |
| `AI/ai.md` | all four AI worked designs to `Design/worked/systems/` |
| `Dictionary/dictionary.md` | A to Z table, filled in Task 8 |

- [ ] **Step 8: Verify and commit**

```bash
bash scripts/check-links.sh && bash scripts/check-style.sh --all
git add -A && git commit -m "vault: move every note into the new tree, structure only"
```

- [ ] **Step 9: STOP. Open the vault in Obsidian and look at it.**

This is the cheap rejection point named in the spec. Browse the sidebar, try to find five notes without searching. If the tree is wrong, `git revert` this commit and fix the plan. No rewriting starts until this checkpoint passes.

---

## Task 5: The four merges

Each merge was approved individually in the spec. Merges run before the rewrite so the rewrite pass sees final files.

**Files:**
- Create: `Design/system-design/designing-the-four-layers.md`
- Delete: `backend-design.md`, `database-design.md`, `frontend-design.md`, `infrastructure-design.md`
- Modify: `Cloud/kubernetes/kubernetes-basics.md`, `Cloud/kubernetes/kubernetes-docker-cicd.md`
- Move: `Dictionary/cdn.md`, `Dictionary/canary-release.md`, `Dictionary/exponential-backoff.md`
- Modify: `Interviews/prep-checklist.md`, delete `Interviews/practice/sprint-list.md`

- [ ] **Step 1: M1, the four layer notes become one**

Create `designing-the-four-layers.md` with one H2 per layer (client, backend, data, deployment), carrying every sentence from all four sources. Order matches the order you would design them in an interview. Then delete the four originals and repoint their links.

```bash
grep -rn "\[\[backend-design\]\]\|\[\[database-design\]\]\|\[\[frontend-design\]\]\|\[\[infrastructure-design\]\]" --include="*.md" vault
```

Every hit becomes `[[designing-the-four-layers]]`.

- [ ] **Step 2: M2, split kubernetes-docker-cicd and merge its Kubernetes half**

Three-way split of the 193 line note: the Kubernetes part merges into `kubernetes-basics.md`, the Docker part becomes `Cloud/kubernetes/docker.md`, the CI/CD part becomes `Cloud/cicd/pipelines.md`. Nothing is dropped; the file ceases to exist only once every section has a new home.

- [ ] **Step 3: M3, the three terms become Dictionary entries**

Rewrite `cdn.md`, `canary-release.md`, `exponential-backoff.md` into the Rule 5 entry shape: full name in the title, one `[!tldr]`, a few lines of detail, a **Shows up in:** line. Content is preserved, only the shape changes.

- [ ] **Step 4: M4, prep-checklist absorbs sprint-list**

Fold the sprint list in as its own H2 inside `prep-checklist.md`, keeping every item. Delete `sprint-list.md` and repoint `[[sprint-list]]`.

- [ ] **Step 5: Verify nothing was lost and commit**

```bash
bash scripts/check-snippets.sh pre-rewrite
bash scripts/check-links.sh
bash scripts/check-style.sh --all
git add -A && git commit -m "vault: merge the four approved note pairs"
```

Expected: all three clean.

---

## Task 6: The 19 splits

A split moves text between files. It never deletes text, which is why `check-snippets.sh` is the gate.

**Files:** the 19 notes named in the spec's split table, plus the 7 borderline ones judged here.

- [ ] **Step 1: Split, one note at a time, largest first**

Order: `service-layer` (804), `ride-booking-worked-example` (570), `aggregation` (500), `write-scaling` (444), `oauth-token-lifecycle` (429), `puzzles-scheduling` (419), `puzzles-promises` (411), `api-design` (396), `zero-to-millions` (371), `builder` (369), `read-scaling` (347), `coding-implementations` (340), `mongodb/schema-design` (335), `singleton` (331), `monotonic-stack` (330), `number-theory` (319), `promises` (304), `appointment-scheduler` (302), `api-failure-scenarios` (300).

For each: cut at H2 boundaries per the spec's proposed split, give every child a `[!tldr]`, and leave the parent as an entry point linking its children when the material has a spine (`service-layer`, `api-design`, `zero-to-millions`). Where it does not, the parent disappears and its links repoint to the children.

- [ ] **Step 2: Judge the seven borderline notes**

`distributed-transactions` (277), `feature-flags` (277), `campaign-messaging-engine` (273), `config-management` (261), `enterprise-auth-sso` (261), `base-cases-and-transitions` (274), `utility-polyfills` (257). Split only if the note covers separable ideas. A 260 line note that is genuinely one idea stays one note; record the reason in the commit message.

- [ ] **Step 3: Verify after every third split**

```bash
bash scripts/check-snippets.sh pre-rewrite && bash scripts/check-links.sh
```

Expected: exit 0 both. A `MISSING SNIPPET` here means a code block was dropped during a cut, and it names the file.

- [ ] **Step 4: Confirm the length cap holds**

```bash
find vault -name '*.md' | while read -r f; do
  n=$(grep -c '' "$f"); [ "$n" -gt 250 ] && printf '%4d  %s\n' "$n" "$f"
done
```

Expected: only notes you consciously decided to keep long, each with a recorded reason.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "vault: split the oversized notes"
```

---

## Task 7: The rewrite pass, writer agents in parallel

The expensive phase. Roughly 32,000 lines across 13 areas, rewritten to all six rules.

**Dispatch pattern, per the agreed approach:** writers run in parallel within a group, and each finished area is immediately handed to an independent reviewer agent that did not write it. Groups run in sequence so review load stays readable.

| Group | Areas dispatched in parallel |
| --- | --- |
| A | `DSA/`, `JavaScript/`, `React/` |
| B | `Design/object-design/` + `Design/patterns/`, `Design/system-design/` + `Design/scaling/`, `Design/worked/systems/`, `Design/worked/lld/` + `Design/worked/real/` |
| C | `Databases/`, `Kafka/` |
| D | `Backend/`, `Security/`, `Cloud/`, `Operations/` + `AI/` + `Interviews/` |

- [ ] **Step 1: Dispatch the group's writer agents, all in one message**

Each writer gets this brief, with `<AREA>` filled in:

```text
Rewrite every note under vault/<AREA> to the six rules in STYLE.md. Read STYLE.md first, in full.

Hard requirements:
1. Lose nothing. Every claim, number, example, table row and code block in the current file survives. You are changing how it reads, not what it says. If something is genuinely redundant, keep it anyway and list it under REDUNDANT in your report rather than deleting it.
2. Keep the technical words (Rule 4). Throttling, idempotent, backpressure, MVCC, SSR and every term like them stay. Fix hard sentences, never by swapping in a vaguer word.
3. Apply the skeleton (Rule 3): a [!tldr] under the title, H2 sections between --- dividers, bold lead-ins on bullets, tables for anything compared, callouts limited to tldr, tip, warning, example, question. Paragraphs at most 3 lines. One sentence per line in the file, never hard wrapped.
4. Do not create Dictionary entries and do not add [[term]] links for jargon. Instead, every time you had to explain a term inline, append a line to vault/Dictionary/_candidates-<AREA>.md as: TERM | the one sentence meaning | the note you were writing.
5. No em dash or en dash anywhere.

When done, run: bash scripts/check-style.sh --all && bash scripts/check-links.sh

Report back: files rewritten, any note still over 250 lines with the reason, the candidate terms you logged, and anything you were unsure about.
```

- [ ] **Step 2: When a writer returns, dispatch its reviewer immediately**

The reviewer must be a fresh agent that did not do the writing. The repo has a `notes-reviewer` agent for exactly this. Dispatch two per area in parallel, since they catch different things.

```text
Audit vault/<AREA> against the pre-rewrite state. Read STYLE.md first.

Compare each file to its baseline: git show pre-rewrite:<path>

Report, as a list, with file and line:
1. LOST: any claim, number, example, table row or code block in the baseline that is not in the new version and not in any other note. This is the finding that matters most; be exhaustive.
2. VAGUE: any place a technical term was replaced by a loose phrase (Rule 4 violation).
3. STRUCTURE: missing [!tldr], missing dividers, paragraphs over 3 lines, prose that should be a table, notes over 250 lines, callout types outside the five.
4. TONE: throat-clearing openers, praise for the topic, filler words, hard wrapped lines.

Do not fix anything. Report only.
```

- [ ] **Step 3: Apply reviewer findings before the next group starts**

Every LOST finding is fixed. VAGUE, STRUCTURE and TONE findings are fixed unless you disagree with the reviewer, in which case record why in the commit message. Re-run both checkers after fixes.

- [ ] **Step 4: Commit per area**

```bash
bash scripts/check-style.sh --all && bash scripts/check-links.sh && bash scripts/check-snippets.sh pre-rewrite
git add vault/<AREA> && git commit -m "vault: rewrite <AREA> to the style rules"
```

- [ ] **Step 5: Repeat for groups B, C and D**

Do not start a group until the previous group's reviewer findings are fixed and committed.

---

## Task 8: Build the Dictionary

Entries come last, because the rewrite pass is what reveals which terms actually needed explaining.

**Files:**
- Create: `vault/Dictionary/<term>.md`, one per term
- Create: `vault/Dictionary/dictionary.md`, the A to Z index
- Delete: `vault/Dictionary/_candidates-*.md`

- [ ] **Step 1: Consolidate the candidate lists**

```bash
cat vault/Dictionary/_candidates-*.md | sort -u
```

- [ ] **Step 2: Drop every candidate that already has a note**

A `Dictionary/` entry never explains a topic that has its own note (Rule 5). For each candidate:

```bash
find vault -name '<term>.md' -not -path '*/Dictionary/*'
```

A hit means no entry. The term links to that note instead.

- [ ] **Step 3: Write the entries**

One file per surviving term, filename in spoken form (`write-ahead-log.md`, not `wal.md`), following the shape in STYLE.md Rule 5: full name with acronym in the title, one `[!tldr]` sentence, a few lines of detail, a **Shows up in:** line linking the notes that use it properly.

- [ ] **Step 4: Write the A to Z index**

`dictionary.md` holds one table, every term with its one line meaning, sorted. This alone answers most lookups without opening an entry.

- [ ] **Step 5: Check for filename collisions**

```bash
find vault -name '*.md' -exec basename {} \; | sort | uniq -d
```

Expected: empty. A Dictionary entry sharing a filename with a note breaks shortest-path linking across the whole vault.

- [ ] **Step 6: Commit**

```bash
rm vault/Dictionary/_candidates-*.md
git add -A && git commit -m "vault: add the dictionary"
```

---

## Task 9: The linking pass

Now that entries exist, notes link to them on first use.

- [ ] **Step 1: Dispatch one agent per area with the final term list**

```text
For every note under vault/<AREA>: the first time a note uses one of the terms in this list, wrap it as a wikilink. Only the first use in each note. Do not link inside code fences, inline code spans, or headings.

Term list: <the finalised Dictionary index, term to filename>

Then delete any leftover inline explanation of a linked term. A definition next to a link is Rule 5's failure mode.
```

- [ ] **Step 2: Verify every link resolves**

```bash
bash scripts/check-links.sh
```

Expected: exit 0.

- [ ] **Step 3: Verify no term is explained twice**

For a sample of 10 terms:

```bash
grep -rln "<term>" --include="*.md" vault | head
```

Read the hits. Exactly one should define it; the rest should link it.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "vault: link jargon to the dictionary on first use"
```

---

## Task 10: Final verification

**No claim of completeness without these outputs in front of you.**

- [ ] **Step 1: Run every checker**

```bash
bash scripts/check-style.sh --all
bash scripts/check-links.sh
bash scripts/check-snippets.sh pre-rewrite
bash scripts/check-conflicts.sh 2>/dev/null || true
find vault -name '*.md' -exec basename {} \; | sort | uniq -d
```

Expected: exit 0 from each, empty output from the last.

- [ ] **Step 2: Check the structural rules by counting**

```bash
cd vault
echo "notes with no tldr:"; grep -rLl '\[!tldr\]' --include='*.md' . 
echo "notes over 250 lines:"; find . -name '*.md' | while read -r f; do n=$(grep -c '' "$f"); [ "$n" -gt 250 ] && printf '%4d  %s\n' "$n" "$f"; done
echo "callouts outside the five:"; grep -roh '\[![a-z-]*\]' --include='*.md' . | sort -u
echo "indexes with no Filed elsewhere table:"; for f in */[a-z]*.md; do grep -qi 'filed elsewhere' "$f" || echo "$f"; done
```

Expected: no untldr'd notes, only consciously long notes, only the five callout types, every index carrying its redirect table.

- [ ] **Step 3: The human checks, which no script can do**

Pick five topics at random. For each, name the folder you would guess before looking, then look. Count how many you got first try, and how many the `Filed elsewhere` table rescued. Anything that needed a search is a placement bug worth fixing.

Then open three rewritten notes on your phone and read them out loud. Rule 1's check and Rule 4's check are both spoken checks.

- [ ] **Step 4: Final commit and tag**

```bash
git add -A && git commit -m "vault: restructure and rewrite complete"
git tag post-rewrite
```

---

## Self-review notes

**Spec coverage.** Every spec section maps to a task: findability contract to Task 4 step 7 and Task 10 step 2, the tree to Tasks 3 and 4, the file map to Task 4, merges to Task 5, splits to Task 6, Dictionary to Tasks 8 and 9, docs to Task 3, phases to the task order, risks to the checkers in Tasks 1, 2 and 10.

**The one thing the spec had that the plan changes.** The spec put Dictionary creation inside the rewrite pass. That would have four writer agents creating entries for the same term in parallel, with colliding filenames. The plan splits it: writers log candidates, one task builds the entries, one task adds the links. Same outcome, no collisions.

**Known gap.** `Cloud/` against `Infrastructure/` is still open. Task 4 step 2 uses `Cloud/`. Changing it later costs one `git mv` plus one sed, so it is not a blocker.

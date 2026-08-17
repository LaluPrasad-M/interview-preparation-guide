# Contributing

Mechanics for adding to this vault: naming, placement, linking, pull requests, what stays out of the repo, and how to clear a conflict.

---

## Naming

- One topic per file. If a note needs a second `#` heading for an unrelated topic, it is two notes.
- Filenames are kebab-case and read as the topic name: `binary-search.md`, `linked-lists.md`. The filename is what shows up inside `[[binary-search]]`, so it has to read naturally in a sentence.
- No dates, initials, or version suffixes in filenames. Git already tracks who changed what and when.

---

## Where a note belongs

All notes live under `vault/`. Paths in this file are relative to it, so `Security/` means `vault/Security/`.

Each area is a folder inside `vault/` holding one index note named after the folder, plus subfolders when the area is big enough to need them. `Design/` shows the pattern:

```text
vault/Design/
  design.md         the area index, linked from _index.md
  object-design/    one topic per file
  patterns/         one pattern per file
  system-design/    one topic per file
  scaling/          one topic per file
  worked/
    lld/            one machine coding problem per file
    systems/        one system designed from scratch per file
    real/           one real company's design per file
```

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

Folders in that table only exist once they hold a real note. Empty folders and title-only placeholder files are not kept, because a sidebar full of empty files is tiring to read and tells you nothing about what is actually written.

When a note grows too long and gets split into parts, each cluster gets its own folder named after the topic, with the parent note inside it as the entry point. The parent links to its parts, and each part links back with "Part of [[parent]]." A note that has not been split stays a single file in its area folder. One file does not earn a folder.

Example cluster structure:

```text
vault/Design/patterns/
  singleton/
    singleton.md                      the parent entry point
    singleton-pattern-and-examples.md
    singleton-advanced-examples.md
  builder.md                          not split, stays as a file
```

The judgment calls, and how to settle them:

**A thing against a move you make.** In `DSA/`, if you would describe it as "a thing" it goes in the structure folder, if you would describe it as "a move you make" it goes in the pattern folder.

**A concept against a worked design.** `Backend/idempotency` is the concept. `Design/worked/systems/ai-tool-idempotency` is a system that applies it. If it has requirements and a diagram, it is a worked design.

**A note against a dictionary entry.** If it needs more than a short definition and a pointer, it is a note. A `Dictionary/` entry never explains a topic that has its own note; it links to that note instead.

Every index note carries a `Filed elsewhere` table naming what you might reasonably expect in that folder and where it actually went. Adding a note that could plausibly live in two folders means adding a row to the loser's index.

---

## Linking

- Link with bare wikilinks: `[[binary-search]]`. Never `[[DSA/binary-search]]`, because the vault is set to shortest-path links and the folder-prefixed form breaks if a file moves.
- Add new notes to their area index (`Design/design.md` and so on) under the right heading. `vault/_index.md` only links to the area indexes. An unlinked note is a note nobody finds.
- Code fences always carry a language (` ```cpp `, ` ```js `, ` ```sql `) so they highlight on the phone too.
- There is no required note structure. Write each topic in whatever shape suits it.

---

## Submitting changes

Pull before you write, push before you close. Work on a branch, one topic per branch; `main` is the merged state.

```bash
git switch main && git pull
git switch -c <your-name>/<topic>      # e.g. lalu/segment-trees
# ...write...
git add -A && git commit -m "dsa: add segment tree notes"
git push -u origin <your-name>/<topic>
gh pr create --fill
```

Adding to someone else's topic needs no ceremony. Open the PR and merge it. Rewriting or restructuring a topic someone else wrote: say so in the PR description and let them look before merging.

---

## What not to commit

- Anything covered by an NDA, plus recruiter names, interviewer names, or material from a company's internal systems. This repo gets cloned; once something is in history it stays in history.
- Secrets, tokens, `.env` files.
- Multi-megabyte images. Compress screenshots before adding them to `assets/`, because the mobile git clients get slow as history grows.
- Your Obsidian pane layout (`vault/.obsidian/workspace*.json`) and personal scratch dumps (`_inbox/`, which sits outside the vault). Both are gitignored already; don't force-add them.

---

## Resolving conflicts

Markdown merges line by line, so conflicts are usually small and both sides are usually worth keeping.

```bash
git switch <your-branch>
git pull origin main          # conflicts surface here, on your branch, not on main
# edit the conflicted files, then
git add -A && git commit
git push
```

- Resolve on your own branch, never on `main`.
- When two people wrote different content for the same section, keep both and merge the wording. Notes are additive; deleting someone's paragraph to clear a conflict loses work.
- Delete every `<<<<<<<`, `=======`, `>>>>>>>` line. The pre-commit hook blocks a commit that still has one, because a stray marker silently corrupts a note. That hook only runs if you enabled it (see the setup steps), so check by eye as well.
- Never force-push `main`.

# Contributing

Mechanics for adding to this vault: naming, placement, linking, pull requests, what stays
out of the repo, and how to clear a conflict.

## Naming

- One topic per file. If a note needs a second `#` heading for an unrelated topic, it is
  two notes.
- Filenames are kebab-case and read as the topic name: `binary-search.md`,
  `linked-lists.md`. The filename is what shows up inside `[[binary-search]]`, so it has to
  read naturally in a sentence.
- No dates, initials, or version suffixes in filenames. Git already tracks who changed what
  and when.

## Where a note belongs

| Folder | Holds |
| --- | --- |
| `DSA/` | a data structure or algorithm family: `trees.md`, `binary-search.md` |
| `DSA/patterns/` | a technique that spans structures: `two-pointer.md`, `sliding-window.md` |
| `Node/` | Node.js and JavaScript runtime topics |
| `CS-Core/` | DBMS, SQL, OS, networks, OOP |
| `System-Design/` | scaling, caching, case studies |
| `Behavioural/` | STAR stories, questions to ask them |
| `Interviews/` | one file per company, your own debriefs |
| `people/<your-name>/` | your solve log, weak-topic list, anything personal |
| `assets/` | images referenced from notes |

The `DSA/` vs `DSA/patterns/` split is the only one that needs a judgment call: if you'd
describe it as "a thing" it goes in `DSA/`, if you'd describe it as "a move you make" it
goes in `patterns/`.

Personal folders are single-owner. Nobody edits someone else's `people/` folder.

## Linking

- Link with bare wikilinks: `[[binary-search]]`. Never `[[DSA/binary-search]]`, because the
  vault is set to shortest-path links and the folder-prefixed form breaks if a file moves.
- Add new notes to [_index.md](_index.md) under the right heading. The index is the entry
  point; an unlinked note is a note nobody finds.
- Code fences always carry a language (` ```cpp `, ` ```js `, ` ```sql `) so they highlight
  on the phone too.
- There is no required note structure. Write each topic in whatever shape suits it.

## Submitting changes

Pull before you write, push before you close. Work on a branch, one topic per branch;
`main` is the merged state.

```bash
git switch main && git pull
git switch -c <your-name>/<topic>      # e.g. lalu/segment-trees
# ...write...
git add -A && git commit -m "dsa: add segment tree notes"
git push -u origin <your-name>/<topic>
gh pr create --fill
```

Adding to someone else's topic needs no ceremony. Open the PR and merge it. Rewriting or
restructuring a topic someone else wrote: say so in the PR description and let them look
before merging.

## What not to commit

- Anything covered by an NDA, plus recruiter names, interviewer names, or material from a
  company's internal systems. This repo gets cloned; once something is in history it stays
  in history.
- Secrets, tokens, `.env` files.
- Multi-megabyte images. Compress screenshots before adding them to `assets/`, because the
  mobile git clients get slow as history grows.
- Your Obsidian pane layout (`.obsidian/workspace*.json`) and personal scratch dumps
  (`_inbox/`). Both are gitignored already; don't force-add them.

## Resolving conflicts

Markdown merges line by line, so conflicts are usually small and both sides are usually
worth keeping.

```bash
git switch <your-branch>
git pull origin main          # conflicts surface here, on your branch, not on main
# edit the conflicted files, then
git add -A && git commit
git push
```

- Resolve on your own branch, never on `main`.
- When two people wrote different content for the same section, keep both and merge the
  wording. Notes are additive; deleting someone's paragraph to clear a conflict loses work.
- Delete every `<<<<<<<`, `=======`, `>>>>>>>` line. The pre-commit hook blocks a commit that
  still has one, because a stray marker silently corrupts a note. That hook only runs if you
  enabled it (see the setup steps), so check by eye as well.
- Never force-push `main`.

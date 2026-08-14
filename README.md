# Placement Notes

Shared Obsidian vault for placement prep — DSA, Node.js, system design, CS core.
The Git repo is the source of truth. Obsidian is just the editor.

Start at [`_index.md`](_index.md).

## Setup

1. Install [Obsidian](https://obsidian.md) (desktop + phone, both free).
2. Clone:
   ```bash
   git clone git@github.com:LaluPrasad-M/placement-notes.git
   ```
3. Obsidian → **Open folder as vault** → pick the cloned folder.
4. Settings → Community plugins → Browse → install **Git** (`obsidian-git`).
   Set it up as:
   - Auto pull on vault open: **on**
   - Auto commit-and-sync: **off** (prevents conflict storms)
   - Push on commit: **on**

Vault options and enabled core plugins live in `.obsidian/` and are tracked, so a
clone behaves the same everywhere. Your local pane layout is ignored.

## Working rules

- **Pull before you write. Commit and push before you close.**
- Work on your own branch. `main` is the merged, reviewed state.
- One topic file has one owner. Adding to someone else's topic is fine; rewriting it
  needs a PR they look at.
- Personal scratch, solve logs and interview debriefs go in `people/<your-name>/`.
  Nobody else edits those.
- Keep `assets/` small — compress screenshots before adding. Mobile git slows down on
  large history.

## Branch workflow

```bash
git switch -c lalu/segment-trees      # <your-name>/<topic>
# ...write notes...
git add -A && git commit -m "dsa: add segment tree notes"
git push -u origin lalu/segment-trees
gh pr create --fill
```

Resolve conflicts on your own branch (`git pull origin main`), then merge the PR.
That keeps broken merges out of `main`.

## Conventions

- One topic per file, kebab-case names: `binary-search.md`.
- Link topics with `[[wikilinks]]` — backlinks build the topic map automatically.
- Code fences always get a language: ` ```cpp `, ` ```js `, ` ```sql `.
- No imposed note structure. Write each note however that topic wants.

CI blocks any push that leaves merge conflict markers in a note.

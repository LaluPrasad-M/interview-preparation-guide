# Placement Notes

Shared Obsidian vault for placement prep: DSA, Node.js, system design, CS core.
The Git repo is the source of truth. Obsidian is just the editor.

## Where things are

| File | Governs |
| --- | --- |
| [_index.md](_index.md) | the notes themselves; every topic links from here |
| [CONTRIBUTING.md](CONTRIBUTING.md) | naming, where a note belongs, linking, pull requests, what not to commit, resolving conflicts |
| [STYLE.md](STYLE.md) | how an explanation should read: plain language, no generated-sounding text |
| [scripts/check-style.sh](scripts/check-style.sh) | the dash check, run by the pre-commit hook |
| [scripts/check-conflicts.sh](scripts/check-conflicts.sh) | the conflict-marker check, run by the pre-commit hook |

This table is the only place files point at each other. Each file above is complete on its
own and does not defer to the others, so adding a new one means adding a row here and
nothing else.

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

5. Turn on the repo's git hooks, once per clone:
   ```bash
   git config core.hooksPath .githooks
   ```
   Git does not share hooks through a clone, so this step is manual, and nothing checks your
   commits until you run it.

Vault options and enabled core plugins live in `.obsidian/` and are tracked, so a
clone behaves the same everywhere. Your local pane layout is ignored.


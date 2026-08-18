# Interview Preparation Guide

Shared Obsidian vault for interview preparation: DSA, JavaScript, design, databases, infrastructure. The Git repo is the source of truth. Obsidian is just the editor.

---

## Layout

The notes live in `vault/`, and everything else is repo plumbing. Open **`vault/`** as your Obsidian vault, not the repo root, so the sidebar shows notes rather than READMEs and shell scripts.

```text
interview-preparation-guide/
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

`_inbox/` sits outside the vault on purpose. It holds Word documents and Jupyter notebooks, which Obsidian cannot render, so inside the vault they would be dead weight in the sidebar. Drop raw material there through Finder, not through Obsidian.

---

## Where things are

| File | Governs |
| --- | --- |
| [vault/_index.md](vault/_index.md) | the notes themselves; every area links from here |
| [CONTRIBUTING.md](CONTRIBUTING.md) | naming, where a note belongs, linking, pull requests, what not to commit, resolving conflicts |
| [STYLE.md](STYLE.md) | how an explanation should read: plain language, no generated-sounding text |
| [scripts/check-style.sh](scripts/check-style.sh) | the dash check, run by the pre-commit hook |
| [scripts/check-conflicts.sh](scripts/check-conflicts.sh) | the conflict-marker check, run by the pre-commit hook |
| [scripts/check-links.sh](scripts/check-links.sh) | every wikilink resolves, run by the pre-commit hook |
| [scripts/check-snippets.sh](scripts/check-snippets.sh) | no code block silently disappears during a rewrite |

This table is the only place files point at each other. Each file above is complete on its own and does not defer to the others, so adding a new one means adding a row here and nothing else.

---

## Setup

1. Install [Obsidian](https://obsidian.md) (desktop + phone, both free).
2. Clone:
   ```bash
   git clone git@github.com:LaluPrasad-M/interview-preparation-guide.git
   ```
3. Obsidian → **Open folder as vault** → pick the **`vault/`** folder inside the clone.
4. Settings → Community plugins → Browse → install **Git** (`obsidian-git`). Set it up as:
   - Auto pull on vault open: **on**
   - Auto commit-and-sync: **off** (prevents conflict storms)
   - Push on commit: **on**
5. Turn on the repo's git hooks, once per clone:
   ```bash
   git config core.hooksPath .githooks
   ```
   Git does not share hooks through a clone, so this step is manual, and nothing checks your commits until you run it.

Vault options and enabled core plugins live in `vault/.obsidian/` and are tracked, so a clone behaves the same everywhere. Your local pane layout is ignored.

> [!tip] The git plugin still works from a subfolder
> `obsidian-git` walks up from the vault folder to find the repository, so pointing Obsidian at `vault/` does not stop it committing or pulling. It just means the plugin's file list shows paths relative to the repo root rather than the vault.

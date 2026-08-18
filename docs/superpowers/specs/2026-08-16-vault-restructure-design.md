# Vault Restructure and Rewrite

> [!tldr]
> Move 217 notes into folders you can guess, add a `Dictionary/` so every jargon word is explained exactly once, and rewrite every note to the six rules in `STYLE.md`.

---

## Why

The vault was built by sorting an inbox, so it is organised by where material came from rather than where you would look for it. Three symptoms:

**Design is split three ways.** `LLD/`, `OOP/` and `System-Design/` all hold design material. SOLID is in one, patterns in another, entity modelling in a third.

**Worked examples are split three ways.** `worked-designs/` (29 notes), `worked-examples/vymo-websales/` (6 notes) and `case-studies/jio-cinema.md` are the same kind of thing under three names.

**Cross-cutting notes landed wherever they were written.** `cross-site-scripting` sits in `System-Design/concepts/` while the rest of security is in `Security/`. `Deployment/kubernetes-docker-cicd` sits away from `AWS/kubernetes/eks`.

The test this design has to pass: open the vault cold, in five years, and the first folder you guess is the right one. When it is not, the page you landed on tells you where the thing went.

---

## What is already done

`STYLE.md` now carries six rules. Rules 4, 5 and 6 were added for this work.

| Rule | Says |
| --- | --- |
| 1 | a ten-year-old should follow it |
| 2 | it should read like a person wrote it |
| 3 | a glance should be enough, plus the note skeleton and the numeric limits |
| 4 | keep the word, fix the sentence: technical vocabulary is mandatory, plain sentences carry it |
| 5 | a word gets explained once, in one place, and links point at it |
| 6 | an index answers "not here, then where" |

Every decision below follows from those. If a rule and this document disagree, the rule wins.

---

## The findability contract

Three independent ways to reach any note, so a wrong first guess costs one hop.

**1. The folder you would guess.** Names are picked by one test: what word would you type if you wanted this? Not what a librarian would call it. The test is applied per name in the naming table below.

**2. A Filed elsewhere table in every index.** Mandatory under Rule 6. Open the folder you guessed, and if the note is not there, the bottom of the page names where it went and why.

**3. The Dictionary as a router.** Every jargon word is an entry ending in a **Shows up in:** line. Search the word, land on the entry, jump to the real note. This is the path that survives forgetting the tree entirely.

---

## The tree

```text
vault/
  _index.md
  Dictionary/       one entry per jargon word, A to Z
  DSA/              arrays, binary search, trees, graphs, DP, backtracking, greedy, design
  JavaScript/       language, typescript, node, node/server, snippets
  React/            fundamentals and the live coding components
  Design/           object-design, patterns, system-design, scaling, worked
  Databases/        sql, mongodb, redis, modelling, operations, change-data
  Kafka/            flat, 11 notes
  Backend/          API design, idempotency, status codes, realtime transports
  Security/         authentication, authorization, hardening, encryption, JWT, XSS
  Cloud/            aws, kubernetes, cicd
  Operations/       what breaks in production and where to look
  AI/               token optimisation, plus pointers to the AI worked designs
  Interviews/       rounds, experiences, practice lists
```

13 top-level folders. Every one is a word you would say out loud.

### The naming test, name by name

| Folder | You are looking for | Would you type this? | Verdict |
| --- | --- | --- | --- |
| `DSA/` | sliding window | yes, or "arrays" which is the subfolder | keep |
| `JavaScript/` | closures, event loop, `useMemo` of the backend world | yes for language; "Node" is handled by the `node/` subfolder being literally named that | rename from `Node/` |
| `React/` | debounced search component | yes | keep |
| `Design/` | SOLID, or how to design a URL shortener | yes, and it is the merge you asked for | new, absorbs `LLD/`, `OOP/`, `System-Design/` |
| `Databases/` | window functions, shard keys | yes | keep |
| `Kafka/` | rebalancing | yes, you would type the product name | keep |
| `Backend/` | idempotency, status codes | yes | keep |
| `Security/` | JWT, HMAC | yes | keep |
| `Cloud/` | S3 lifecycle, EKS, GitHub Actions | this is the weakest name of the 13, see below | rename from `AWS/` + `Deployment/` |
| `Operations/` | the database is slow at 2am | yes | rename from `Incident-Management/` |
| `AI/` | token optimisation | yes | keep |
| `Interviews/` | what did Vymo ask me | yes | keep |
| `Dictionary/` | what does MVCC stand for | yes | new |

> [!question] The one name worth arguing about
> `Cloud/` holds AWS, Kubernetes and CI/CD. You would probably type "AWS", and AWS is only two thirds of the folder. The alternative is `Infrastructure/`, accurate but longer and less like something you would say. Third option: keep `AWS/` and `Deployment/` separate as today, and accept Kubernetes living in both.
>
> **Default if you say nothing: `Cloud/`.** It is the shortest word that honestly covers all three, and the `Filed elsewhere` table in the old spot makes a wrong guess cost one hop.

### Why `Design/` and not `LLD/` plus `System-Design/`

You named this split as the problem, so the design merges them. Inside, the halves stay obvious:

```text
Design/
  design.md
  object-design/      the LLD half: pillars, SOLID, composition, DI
  patterns/           strategy, factory, observer, builder, singleton
  system-design/      the HLD half: concepts and the layer designs
  scaling/            the ladders: zero to millions, read, write, service layer
  worked/
    lld/              checkout, ride booking
    systems/          the 29 worked designs
    real/             jio-cinema, vymo-websales
```

One area, five doors, and the three kinds of worked example finally sit together under one parent.

---

## Where every file goes

Complete map. Every one of the 217 notes appears exactly once.

### DSA, 27 notes, barely moves

| From | To | Note |
| --- | --- | --- |
| `DSA/*` | `DSA/*` | unchanged, this area already passes the guess test |
| `DSA/problem-lists.md` | `Interviews/practice/dsa-problems.md` | it is a practice list, and all practice lists move together |

`DSA/lru-and-min-stack.md` and `DSA/linked-list/reverse-a-list.md` get a `DSA/data-structures/` parent so the root of `DSA/` holds only method notes (`how-to-solve`, `complexity-and-scale`, `number-theory`).

### JavaScript, 34 notes, renamed from Node

| From | To |
| --- | --- |
| `Node/javascript/*` (10) | `JavaScript/language/*` |
| `Node/typescript/*` (4) | `JavaScript/typescript/*` |
| `Node/runtime/*` (9) | `JavaScript/node/*` |
| `Node/snippets/server/*` (4) | `JavaScript/node/server/*` |
| `Node/snippets/*` (6) | `JavaScript/snippets/*` |
| `Node/node.md` | `JavaScript/javascript.md` |

`Node/runtime/puzzles-promises.md` and `puzzles-scheduling.md` move to `JavaScript/node/puzzles/`, since 830 lines of "what does this print" is its own thing.

### Design, 78 notes, the big merge of `OOP/` (8), `LLD/` (13) and `System-Design/` (60)

| From | To |
| --- | --- |
| `OOP/four-pillars, solid, solid-js-vs-ts, abstract-classes, access-modifiers, overloading-vs-overriding, js-vs-ts-compilation` | `Design/object-design/` |
| `LLD/abstraction-and-dependency-injection, inheritance-vs-composition` | `Design/object-design/` |
| `LLD/six-step-framework` | `Design/object-design/how-to-do-an-lld-round.md` |
| `LLD/patterns/*` (6) | `Design/patterns/` |
| `LLD/checkout-worked-example, ride-booking-worked-example` | `Design/worked/lld/` |
| `LLD/machine-coding-list` | `Interviews/practice/machine-coding.md` |
| `System-Design/concepts/*` minus XSS (14) | `Design/system-design/` |
| `System-Design/scaling/*` (5) | `Design/scaling/` |
| `System-Design/terms/*` (3) | `Dictionary/` |
| `System-Design/worked-designs/*` (29) | `Design/worked/systems/` |
| `System-Design/case-studies/jio-cinema` | `Design/worked/real/` |
| `System-Design/worked-examples/vymo-websales/*` (6) | `Design/worked/real/vymo-websales/` |
| `System-Design/concepts/cross-site-scripting` | `Security/` |

The 29 worked designs keep the grouping your index already uses (core infrastructure, payments, concurrency, webhooks, search and geo, realtime and AI), expressed as headings in `Design/worked/systems/` rather than more folders.

### Databases, 30 notes, concepts folder split

| From | To |
| --- | --- |
| `Databases/sql/*` (8) | unchanged |
| `Databases/mongodb/*` (5) | unchanged |
| `Databases/redis/*` (3) | unchanged |
| `concepts/normalization, schema-design-questions, food-delivery-schema, choosing-a-datastore, sql-vs-mongodb` | `Databases/modelling/` |
| `concepts/zero-downtime-migration, locking-strategies, replication-partitioning-sharding, replication-lag` | `Databases/operations/` |
| `concepts/change-data-capture, inbox-pattern, out-of-order-events` | `Databases/change-data/` |
| `concepts/clickhouse` | `Databases/clickhouse.md` |

`concepts/` becomes three folders because 14 unrelated notes under one word is the same problem as the vault had at the top level.

### The rest

| From | To | Why |
| --- | --- | --- |
| `Kafka/*` (11) | unchanged, stays flat | 11 notes is scannable, and every name is specific |
| `Backend/*` (5) | unchanged | already predictable |
| `Security/*` (6) | unchanged, gains `cross-site-scripting` | |
| `AWS/compute, s3` | `Cloud/aws/` | |
| `AWS/kubernetes/*`, `Deployment/kubernetes-docker-cicd` | `Cloud/kubernetes/` | the two Kubernetes homes become one |
| `AWS/deployment/*`, `Deployment/github-actions` | `Cloud/cicd/` | |
| `Incident-Management/categories` | `Operations/what-breaks-in-production.md` | |
| `AI/*` (2) | unchanged | |
| `Interviews/experiences, prep-checklist` | unchanged | |
| `Interviews/sprint-list` | `Interviews/practice/sprint-list.md` | joins the other practice lists |

---

## Merges, each needing your yes

Splits I will just do, because a split loses nothing. Merges can lose content, so each one is listed here and none happens without approval.

| # | Merge | Lines in | Argument |
| --- | --- | --- | --- |
| M1 | `backend-design` + `database-design` + `frontend-design` + `infrastructure-design` into `Design/system-design/designing-the-four-layers.md` | 53 + 50 + 39 + 50 | four thin notes that only make sense read together, and each one is a section not a topic |
| M2 | `Deployment/kubernetes-docker-cicd` splits, and its Kubernetes half merges into `Cloud/kubernetes/kubernetes-basics` | 193 into 3 | one note currently covers three products, and its Kubernetes part duplicates `kubernetes-basics` |
| M3 | `System-Design/terms/cdn, canary-release, exponential-backoff` become Dictionary entries | 14 + 21 + 26 | Rule 5 says short definitions live in the Dictionary, and that is exactly what these are |
| M4 | `Interviews/prep-checklist` absorbs `Interviews/sprint-list` | 73 + 88 | both answer "what do I revise and in what order" |

**Not merging, on purpose:**

`Backend/idempotency` and `worked-designs/ai-tool-idempotency` stay separate. One is the concept, one is a worked design that applies it. Cross-linked instead.

The JS against TS family (`patterns-js-vs-ts`, `solid-js-vs-ts`, `js-vs-ts-compilation`) stays as three notes. They overlap in flavour, not in content: patterns, principles and compilation output are different questions.

`webhook-delivery`, `webhook-ingestion` and `webhook-signatures` stay as three. Sending, receiving and signing are three different interview answers.

---

## Splits

Rule 3 caps a note at around 250 lines. 19 notes are over. Each becomes 2 to 4 linked notes, with the parent kept as the entry point where the material has a natural spine.

| Note | Lines | Split into |
| --- | --- | --- |
| `service-layer` | 804 | latency amplification, retry storms and circuit breakers, event loop lag, plus a parent |
| `ride-booking-worked-example` | 570 | requirements and entities, matching and state machine, the code |
| `mongodb/aggregation` | 500 | find operators, pipeline stages, cursors and change streams |
| `write-scaling` | 444 | the write path (WAL, fsync, batching), then sharding and the viral counter |
| `oauth-token-lifecycle` | 429 | the refresh scheduler, then the interceptor and promise sharing |
| `puzzles-scheduling` | 419 | two notes of puzzles, grouped by what they test |
| `puzzles-promises` | 411 | same treatment |
| `api-design` | 396 | the design flow, pagination and filtering, auth and versioning |
| `zero-to-millions` | 371 | the nine stages, then the per workload ladders |
| `patterns/builder` | 369 | the pattern, then the worked build |
| `read-scaling` | 347 | caching and replicas, then indexes, planners and observability |
| `react/coding-implementations` | 340 | five components per note |
| `mongodb/schema-design` | 335 | embed against reference, then denormalisation and the checklist |
| `patterns/singleton` | 331 | the pattern, then the Node module cache pitfall |
| `monotonic-stack` | 330 | the pattern, then the problem set |
| `number-theory` | 319 | primes and GCD, then bit tricks and fast power |
| `promises` | 304 | combinators, then error propagation |
| `appointment-scheduler` | 302 | the Redis rejection layer, then the outbox commit |
| `api-failure-scenarios` | 300 | the seven failures, then the correctness toolbox |

Seven more sit between 250 and 280 (`distributed-transactions`, `feature-flags`, `campaign-messaging-engine`, `config-management`, `enterprise-auth-sso`, `base-cases-and-transitions`, `utility-polyfills`). Judged individually during the pass: split only if they cover separable ideas, since a 260 line note that is genuinely one idea should stay one note.

---

## The Dictionary

One entry per jargon word, flat folder, filename is the spoken form (`write-ahead-log.md`, not `wal.md`) so `[[write-ahead-log]]` reads naturally in a sentence.

**Entry shape** is fixed by Rule 5: full name with acronym in the title, one `[!tldr]` sentence, a few lines of detail, then a **Shows up in:** line linking the notes that use it properly.

**The boundary:** an entry never explains something that has its own note. `sharding` has a note, so `[[sharding]]` points at the note and no entry exists. `MVCC` has no note, so it gets an entry.

**Starting set,** harvested by scanning the vault for terms used without definition. Roughly 40 to 60 expected. First pass candidates:

```text
amortised          backpressure       bloom filter       CAP theorem
CDN                canary release     consistent hashing CQRS
DLQ                exponential backoff fan out           fsync
gap lock           HMAC               idempotency key    ISR
JIT                LSM tree           MVCC               NFR
OIDC               p99                quorum             RPO and RTO
SLA and SLO        SSR                TDZ                TTL
WAL                write amplification thundering herd   tombstone
sargable           skip list          scatter gather     sidecar
outbox             leader election    sticky session     hot key
```

The real list comes out of the rewrite pass. Every time a note has to stop and explain a word, that explanation becomes an entry and the note gets a link.

`Dictionary/dictionary.md` is the index: an A to Z table of every term with its one line meaning, so the index alone answers most lookups without opening anything.

---

## Documentation updates

| File | Change |
| --- | --- |
| `STYLE.md` | done: Rules 4, 5, 6 added, Rule 1 corrected where it contradicted Rule 5 |
| `CONTRIBUTING.md` | the folder table replaced with the new tree, plus what makes a Dictionary entry, plus the mandatory Filed elsewhere table |
| `README.md` | layout tree refreshed |
| `scripts/check-links.sh` | new: every `[[wikilink]]` resolves to a file that exists. 523 links are about to move, so this is how we know nothing broke |

Docs are written before the notes move, so implementation follows the docs rather than being retrofitted into them.

---

## How it gets done

Six phases. Each one ends in a state you could stop at without leaving the vault broken.

| Phase | Work | Done when |
| --- | --- | --- |
| 0 | `CONTRIBUTING.md`, `README.md`, `scripts/check-links.sh` | link checker passes on the current vault, giving a clean baseline |
| 1 | `git mv` every file into the new tree, fix all wikilinks, rewrite the 13 area indexes with Filed elsewhere tables | link checker passes, no content changed, diff is pure moves |
| 2 | the 19 splits, plus the 6 judgment calls | no note over 250 lines without a written reason |
| 3 | the approved merges (M1 to M4) | merged notes carry every idea from both sources |
| 4 | the rewrite pass, area by area, to all six rules, extracting Dictionary entries as they surface | every note passes the Rule 3 skeleton and the Rule 4 vocabulary check |
| 5 | verification sweep | link checker, style check, and two `notes-reviewer` agents in parallel per area |

**Phase 1 is the reversible one.** Pure moves and link fixes, so if the tree feels wrong once you see it in Obsidian, it costs one commit to change. That is deliberate: you approve the tree on paper here, and again in practice there, before a single word gets rewritten.

**Phase 4 is the expensive one.** 217 notes at roughly 32,000 lines. Done per area with parallel agents, one area per branch, so review arrives in pieces you can actually read rather than one 30,000 line diff.

**Verification is not self-assessment.** The repo already has a `notes-reviewer` agent that audits vault changes against `_inbox` source material and the repo rules. Two run in parallel per area, because they catch different things.

---

## Risks

| Risk | Mitigation |
| --- | --- |
| Rewriting loses detail that was the whole point of a note | `_inbox` keeps the source material, and `notes-reviewer` diffs against it. Merges need approval, splits do not lose content |
| 523 wikilinks break during the move | `scripts/check-links.sh` runs in phase 0 to get a clean baseline, then after every phase |
| The tree looks right on paper and wrong in Obsidian | phase 1 is pure moves, reviewed in the app before any rewriting starts |
| Plain language quietly deletes the technical words | Rule 4 exists for exactly this, and its check is part of phase 5 |
| Vymo material is client confidential | it moves to `Design/worked/real/vymo-websales/` with its existing warning callout intact, and stays out of any public push |

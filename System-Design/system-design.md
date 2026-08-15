# System Design

> [!tldr]
> Index for everything under `System-Design/`. Concepts are the decisions, terms are the quick lookups, case studies are real systems under real load.

---

## Concepts

The five places a design decision gets made, front to back, plus two that cut across them.

| Note                         | Covers                                                           |
| ---------------------------- | ---------------------------------------------------------------- |
| [[frontend-design]]          | the part users touch, and what makes it fast or slow             |
| [[backend-design]]           | scaling, service communication, caching, protecting yourself     |
| [[database-design]]          | indexes, replication, sharding, the decisions you cannot undo    |
| [[infrastructure-design]]    | containers, infrastructure as code, deploys, autoscaling limits  |
| [[third-party-integrations]] | what to offload, and what it costs you                           |
| [[cross-site-scripting]]     | how injected scripts run in your page, and how to stop them      |
| [[message-ordering]]         | messages arriving out of order, and notification race conditions |

---

## Terms

| Note                    | In one line                            |
| ----------------------- | -------------------------------------- |
| [[exponential-backoff]] | doubling the wait between retries      |
| [[canary-release]]      | shipping to a few users first          |
| [[cdn]]                 | a cache layer in front of your servers |

---

## Case studies

| Note | System |
| --- | --- |
| [[jio-cinema]] | streaming an IPL match: priority tiers, snapshots, panic modes |

---

## Worked examples

One real system, written up end to end, rather than a topic.

| Example | Covers |
| --- | --- |
| [[vymo-websales]] | a website to CRM lead integration: [[overview-and-requirements]], [[hld]], [[lld]], [[caching-and-errors]], and [[patterns-worth-stealing]] |

> [!warning] The Vymo example contains work material
> Real client name, SLA, encryption standard and cache TTLs. Fine in a private repo, and to be reviewed before this repo is ever public. [[patterns-worth-stealing]] is the sanitised version, safe to discuss anywhere.

---

## Where to learn more

- [Jio Cinema system design talk](https://www.youtube.com/watch?v=36N1Bz7qW0A)
- [ByteByteGo](https://bytebytego.com/) for HLD and LLD
- [Jordan has no life](https://www.youtube.com/@jordanhasnolife5163)

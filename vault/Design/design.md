# Design

> [!tldr]
> The merge of OOP, LLD and System Design. Object design and patterns first, then system design concepts and scaling ladders, then the worked designs that reuse all of it.

---

## Object design

| Note | Covers |
| --- | --- |
| [[four-pillars]] | encapsulation, abstraction, inheritance, polymorphism, plus abstract methods |
| [[solid]] | the five principles, each with its canonical bad example |
| [[solid-js-vs-ts]] | each principle in both languages, plus two interview answers |
| [[overloading-vs-overriding]] | prototype shadowing against overload signatures |
| [[js-vs-ts-compilation]] | what each pillar actually compiles down to |
| [[abstract-classes]] | abstract classes and methods, with and without, abstract class against interface |
| [[access-modifiers]] | public, protected and private, and why TypeScript's private is not enforcement |
| [[how-to-do-an-lld-round]] | the sequential model for any LLD interview |
| [[abstraction-and-dependency-injection]] | how abstraction, DI and polymorphism connect |
| [[inheritance-vs-composition]] | the fragile base class, the gorilla and banana, and the full interview answer |

---

## Patterns

| Note | Covers |
| --- | --- |
| [[strategy]] | massive `if/else` logic dictating behaviour |
| [[factory]] | scattered or conditional object instantiation |
| [[observer]] | many unrelated systems reacting to one change |
| [[builder]] | too many constructor parameters, some optional |
| [[singleton]] | exactly one instance across the application |
| [[patterns-js-vs-ts]] | each pattern in both languages, the Node module cache pitfall, three interview answers |

---

## Scaling

| Note | Covers |
| --- | --- |
| [[zero-to-millions]] | the nine stages, the stateless web tier, and the scaling ladders per workload |
| [[read-scaling]] | twenty stages from a single DB to query planners and observability |
| [[write-scaling]] | WAL and fsync, batching, MVCC pressure, sharding, and the viral counter |
| [[service-layer]] | latency amplification, retry storms, circuit breakers, event loop lag |
| [[distributed-transactions]] | 2PC, Saga, compensation, the outbox pattern and its relay |

---

## System design

| Note | Covers |
| --- | --- |
| [[capacity-estimation]] | the formulas, the adjustments people forget, and five worked estimates |
| [[building-blocks]] | twelve components, each with its analogy, mechanics, trade off and curveball |
| [[consistency-models]] | the six models, and the four that 95 percent of interviews use |
| [[nfr-decision-table]] | dominant NFR to architecture, plus async fanout against async buffered |
| [[fault-tolerance]] | circuit breakers, bulkheads, load shedding, graceful degradation |
| [[monolith-vs-microservice]] | the comparison table and why nanoservices are an anti pattern |
| [[workflow-engines]] | durable workflows, why Kafka alone is not enough |
| [[designing-the-four-layers]] | the client, backend, data and deployment layers of a design |
| [[third-party-integrations]] | designing around systems you do not control |
| [[message-ordering]] | when order matters and how to keep it |
| [[card-payment-flow]] | the five players, authorization against settlement |

---

## Worked designs

### Core infrastructure

| Note | Covers |
| --- | --- |
| [[distributed-id-generation]] | 64 bit Snowflake IDs with Postgres leasing the machine ID |
| [[api-gateway]] | the boundary between the public internet and the trusted network |
| [[enterprise-auth-sso]] | sign once with a vaulted key, verify everywhere in RAM |
| [[feature-flags]] | central truth, local evaluation, sub 200 ms kill switch |
| [[config-management]] | the sidecar as a background file downloader |
| [[multi-region-cart]] | active active with tombstones and last write wins |
| [[oauth-token-lifecycle]] | proactive scheduler plus reactive interceptor, and promise sharing |

### Payments and ledgers

| Note | Covers |
| --- | --- |
| [[payment-ingestion]] | three layers of defence against a double charge |
| [[billing-ledger]] | append only ledger, unique idempotency key, materialized balance |
| [[shopping-cart]] | why SQL, the version column, and inventory validated but not reserved |
| [[url-shortener]] | Base62 over an incrementing ID, cache first, async analytics |
| [[applicant-tracking-system]] | multi tenant SQL, optimistic locking on stages, search split out |

### Concurrency and decoupling

| Note | Covers |
| --- | --- |
| [[appointment-scheduler]] | reject in Redis, then commit with an outbox |
| [[campaign-messaging-engine]] | tiered topics beat a single partition key |
| [[matchmaking-fanout]] | one event becomes 500 independent tasks |
| [[flash-sale-inventory]] | Redis as a concurrency layer, not a cache |
| [[circuit-breaker]] | the state machine, where state lives, four production failures |

### Webhooks

| Note | Covers |
| --- | --- |
| [[webhook-ingestion]] | accept fast, and let the database resolve duplicates |
| [[webhook-delivery]] | never sleep in a consumer, publish to a delay topic |

### Search and geo

| Note | Covers |
| --- | --- |
| [[typeahead-search]] | precompute prefixes, scatter gather, warm the cache |
| [[geospatial-discovery]] | Elasticsearch for filters, Redis for volatility |
| [[proximity-discovery]] | Mongo, then Redis GEO, then spatial grids |

### Realtime and AI

| Note | Covers |
| --- | --- |
| [[realtime-leaderboard]] | a sorted set is a hash table plus a skip list |
| [[voice-orchestrator]] | overlapping streams beat the 500 ms barrier |
| [[ai-tool-idempotency]] | lock on the conversation turn, not the arguments |
| [[ai-agent-orchestration]] | document state plus optimistic concurrency |
| [[analytics-ingestion]] | batch in, Kafka through, materialized views out |
| [[observability-platform]] | metrics and logs are different workloads, alerts off the stream |
| [[notification-delivery]] | why the API and Kafka both exist, retry topics, DLQ |

---

## Machine coding practice

| Note | Covers |
| --- | --- |
| [[checkout-worked-example]] | four patterns wired together, plus the pattern mapping table |
| [[ride-booking-worked-example]] | the six steps end to end, the request trace, the composition root |

---

## Case studies

| Note | Covers |
| --- | --- |
| [[jio-cinema]] | streaming an IPL match: priority tiers, snapshots, panic modes |

---

## Worked examples

One real system, written up end to end, rather than a topic.

| Note | Covers |
| --- | --- |
| [[vymo-websales]] | a website to CRM lead integration: [[overview-and-requirements]], [[hld]], [[websales-lld]], [[caching-and-errors]], and [[patterns-worth-stealing]] |

> [!warning] The Vymo example contains work material
> Real client name, SLA, encryption standard and cache TTLs. Fine in a private repo, and to be reviewed before this repo is ever public. [[patterns-worth-stealing]] is the sanitised version, safe to discuss anywhere.

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[idempotency]] | `Backend/` | it is an API design technique, not a system design concept |
| [[jwt]] | `Security/` | token structure and signature maths are a security topic |
| [[internals]] | `Kafka/` | partitioning, replication and consumer groups are Kafka mechanics, not design concepts |
| [[cross-site-scripting]] | `Security/` | the attack and its defences, filed with the rest of security |
| [[machine-coding]] | `Interviews/practice/` | a practice problem list, not a worked design |
| [[cdn]] | `Dictionary/` | a short definition belongs in the dictionary, per STYLE.md Rule 5 |
| [[canary-release]] | `Dictionary/` | a short definition belongs in the dictionary, per STYLE.md Rule 5 |
| [[exponential-backoff]] | `Dictionary/` | a short definition belongs in the dictionary, per STYLE.md Rule 5 |

---

## Where to learn more

- [Jio Cinema system design talk](https://www.youtube.com/watch?v=36N1Bz7qW0A)
- [ByteByteGo](https://bytebytego.com/) for HLD and LLD
- [Jordan has no life](https://www.youtube.com/@jordanhasnolife5163)

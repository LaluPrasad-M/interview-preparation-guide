# System Design

> [!tldr]
> Concepts first, then the scaling ladders, then the worked designs. Every worked design reuses the same handful of ideas.

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

## Concepts

| Note | Covers |
| --- | --- |
| [[capacity-estimation]] | the formulas, the adjustments people forget, and five worked estimates |
| [[building-blocks]] | twelve components, each with its analogy, mechanics, trade off and curveball |
| [[consistency-models]] | the six models, and the four that 95 percent of interviews use |
| [[nfr-decision-table]] | dominant NFR to architecture, plus async fanout against async buffered |
| [[fault-tolerance]] | circuit breakers, bulkheads, load shedding, graceful degradation |
| [[monolith-vs-microservice]] | the comparison table and why nanoservices are an anti pattern |
| [[workflow-engines]] | durable workflows, why Kafka alone is not enough |
| [[backend-design]] | the backend layer of a design |
| [[database-design]] | the data layer of a design |
| [[frontend-design]] | the client layer of a design |
| [[infrastructure-design]] | the deployment layer of a design |
| [[third-party-integrations]] | designing around systems you do not control |
| [[message-ordering]] | when order matters and how to keep it |
| [[card-payment-flow]] | the five players, authorization against settlement |
| [[cross-site-scripting]] | the attack and the defences |

---

## Terms

[[cdn]], [[canary-release]], [[exponential-backoff]].

---

## Worked designs

### Core infrastructure

| Design | The central idea |
| --- | --- |
| [[distributed-id-generation]] | 64 bit Snowflake IDs with Postgres leasing the machine ID |
| [[api-gateway]] | the boundary between the public internet and the trusted network |
| [[enterprise-auth-sso]] | sign once with a vaulted key, verify everywhere in RAM |
| [[feature-flags]] | central truth, local evaluation, sub 200 ms kill switch |
| [[config-management]] | the sidecar as a background file downloader |
| [[multi-region-cart]] | active active with tombstones and last write wins |
| [[oauth-token-lifecycle]] | proactive scheduler plus reactive interceptor, and promise sharing |

### Payments and ledgers

| Design | The central idea |
| --- | --- |
| [[payment-ingestion]] | three layers of defence against a double charge |
| [[billing-ledger]] | append only ledger, unique idempotency key, materialized balance |
| [[shopping-cart]] | why SQL, the version column, and inventory validated but not reserved |
| [[url-shortener]] | Base62 over an incrementing ID, cache first, async analytics |
| [[applicant-tracking-system]] | multi tenant SQL, optimistic locking on stages, search split out |

### Concurrency and decoupling

| Design | The central idea |
| --- | --- |
| [[appointment-scheduler]] | reject in Redis, then commit with an outbox |
| [[campaign-messaging-engine]] | tiered topics beat a single partition key |
| [[matchmaking-fanout]] | one event becomes 500 independent tasks |
| [[flash-sale-inventory]] | Redis as a concurrency layer, not a cache |
| [[circuit-breaker]] | the state machine, where state lives, four production failures |

### Webhooks

| Design | The central idea |
| --- | --- |
| [[webhook-ingestion]] | accept fast, and let the database resolve duplicates |
| [[webhook-delivery]] | never sleep in a consumer, publish to a delay topic |

### Search and geo

| Design | The central idea |
| --- | --- |
| [[typeahead-search]] | precompute prefixes, scatter gather, warm the cache |
| [[geospatial-discovery]] | Elasticsearch for filters, Redis for volatility |
| [[proximity-discovery]] | Mongo, then Redis GEO, then spatial grids |

### Realtime and AI

| Design | The central idea |
| --- | --- |
| [[realtime-leaderboard]] | a sorted set is a hash table plus a skip list |
| [[voice-orchestrator]] | overlapping streams beat the 500 ms barrier |
| [[ai-tool-idempotency]] | lock on the conversation turn, not the arguments |
| [[ai-agent-orchestration]] | document state plus optimistic concurrency |
| [[analytics-ingestion]] | batch in, Kafka through, materialized views out |
| [[observability-platform]] | metrics and logs are different workloads, alerts off the stream |
| [[notification-delivery]] | why the API and Kafka both exist, retry topics, DLQ |

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
| [[vymo-websales]] | a website to CRM lead integration: [[overview-and-requirements]], [[hld]], [[websales-lld]], [[caching-and-errors]], and [[patterns-worth-stealing]] |

> [!warning] The Vymo example contains work material
> Real client name, SLA, encryption standard and cache TTLs. Fine in a private repo, and to be reviewed before this repo is ever public. [[patterns-worth-stealing]] is the sanitised version, safe to discuss anywhere.

---

## Where to learn more

- [Jio Cinema system design talk](https://www.youtube.com/watch?v=36N1Bz7qW0A)
- [ByteByteGo](https://bytebytego.com/) for HLD and LLD
- [Jordan has no life](https://www.youtube.com/@jordanhasnolife5163)

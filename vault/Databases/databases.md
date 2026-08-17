# Databases

> [!tldr]
> SQL for invariants you cannot afford to break, Mongo for documents that grow. Most interview depth lives in indexing, concurrency and the execution plan.

---

## SQL

| Note | Covers |
| --- | --- |
| [[execution-order]] | the eleven step order and the mental story behind it |
| [[joins]] | inner, left, missing data, fan out, the accidental inner join, `EXISTS` against `IN` |
| [[window-functions]] | `PARTITION BY`, the rank family, latest per group, running totals, `LAG` |
| [[query-patterns]] | group by, duplicates, CTEs, recursion, `CASE`, sargability, the rapid fire table |
| [[data-types]] | numeric, string, date, JSON, UUID, ENUM, and the best practice table |
| [[study-roadmap]] | the three tiers and the priority order to learn them in |
| [[invariants]] | the eleven invariant types and which layer enforces each |
| [[read-lock-contention]] | MVCC, the long read that bloats everything, metadata locks, gap locks |

---

## MongoDB

| Note | Covers |
| --- | --- |
| [[schema-design]] | access patterns first, aggregate roots, embed against reference, denormalisation, the checklist |
| [[consistency-and-transactions]] | document atomicity, transactions and their cost, write and read concern |
| [[sharding]] | shard key properties, scatter gather, hot shards |
| [[indexing]] | explain, the left prefix rule, ESR, covered queries, TTL and sparse indexes |
| [[aggregation]] | find operators, every pipeline stage, cursor streaming, change streams |

---

## Redis

| Note | Covers |
| --- | --- |
| [[redis-use-cases]] | the ten use cases, cache aside in Node, and the lock that stops a stampede |
| [[caching-problems]] | stampede, avalanche, penetration, invalidation, hot keys, eviction, the 20 percent hit ratio framework |
| [[redis-cluster]] | 16384 hash slots, why it is not classic consistent hashing |

---

## Modelling

| Note | Covers |
| --- | --- |
| [[choosing-a-datastore]] | the choose when and avoid when matrix for twelve technologies, plus the cheat sheet |
| [[sql-vs-mongodb]] | the invariants framework, what SQL gives you free, when NFRs decide |
| [[normalization]] | the anomalies it solves, the worked example, why Mongo is called non relational |
| [[schema-design-questions]] | the ten questions to walk in order |
| [[food-delivery-schema]] | those ten questions applied end to end across eight tables |
| [[clickhouse]] | columnar storage, why it is fast, and where it does not belong |

---

## Operations

| Note | Covers |
| --- | --- |
| [[replication-partitioning-sharding]] | three words, three problems |
| [[locking-strategies]] | optimistic, pessimistic and the atomic update people forget |
| [[zero-downtime-migration]] | expand and contract, backfill strategies, archiving, the risks |
| [[replication-lag]] | read your own writes, eventual, synchronous, monotonic reads |

---

## Change data

| Note | Covers |
| --- | --- |
| [[inbox-pattern]] | reliable consumption, and how it pairs with the outbox |
| [[out-of-order-events]] | timestamps, version numbers, state machines |
| [[change-data-capture]] | log tailing against polling, Debezium, outage recovery, log truncation |

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[read-scaling]] | `Design/scaling/` | it is the twenty stage scaling ladder for reads, not a database mechanic |
| [[write-scaling]] | `Design/scaling/` | WAL, batching and sharding as a scaling story, not a standalone database note |
| [[distributed-transactions]] | `Design/scaling/` | cross service transaction patterns, not a single database's mechanics |

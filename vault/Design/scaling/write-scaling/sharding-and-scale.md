# Sharding and the Viral Counter

> [!tldr]
> Horizontal write scaling requires distributing data across machines via sharding, but uneven traffic creates hotspots, which requires counter sharding, and the viral like counter demonstrates the complete architecture.

Part of [[write-scaling]].

---

## Stage 7: partitioning, sharding and hotspot management

This began once we exhausted almost every single node write optimisation: Kafka buffering, Redis aggregation, write coalescing, batching, append only ingestion, CQRS and materialized projections.

All those dramatically reduced synchronous pressure, mutation frequency, WAL amplification, lock contention and MVCC churn. But eventually a hard physical reality appeared: one machine cannot scale forever. CPU, memory, disk bandwidth, WAL throughput and network are all finite.

That is the birth of partitioning and sharding.

> [!tip] The deepest realisation of this stage
> Scalability problems are often distribution problems. Not merely more traffic, but uneven traffic.

### Partitioning against sharding

Partitioning broadly means splitting data logically, sometimes still on the same physical machine, for example `orders_2024`, `orders_2025`, `orders_2026`. It improves query pruning, maintenance, archival operations, vacuum locality and index locality. This is especially important in PostgreSQL for very large relational tables.

Sharding introduces distribution across multiple physical nodes:

```text
users 1-1M   -> shard A
users 1M-2M  -> shard B
users 2M-3M  -> shard C
```

Now CPU, storage, WAL, lock pressure and throughput are all distributed. This is the true horizontal scaling breakthrough.

### The shard key is everything

The shard key controls write distribution, query locality, hotspot formation, rebalance complexity and cross shard coordination. This is one of the highest return interview topics.

A well distributed shard key such as `user_id` often spreads traffic evenly. Bad shard keys such as `country`, `celebrity_id` or `timestamp` create hotspot shards, where one shard is overloaded and the others sit mostly idle.

### Hotspot management

Distributed systems often fail due to hot mutable state. The same pattern already appeared as Redis hot keys, lock contention, hot rows and counter bottlenecks. Now the exact same problem reappears at distributed storage level.

**Counter sharding.** Instead of `post:123:likes`, systems evolved toward `post:123:likes:1`, `post:123:likes:2`, `post:123:likes:3` and so on. This distributes writes, Redis pressure, Kafka partition pressure and DB mutation pressure, and it is one of the most important hotspot mitigation strategies.

### Cross shard complexity

Once data is distributed, distributed queries are expensive. Systems struggle with cross shard joins, distributed transactions, multi shard consistency, global ordering and query fanout. This becomes one of the biggest operational costs of sharding.

Because cross shard coordination is expensive, systems increasingly evolve toward denormalisation, materialized projections, precomputed views and async synchronisation. Distribution pushes systems toward denormalisation.

### Resharding is operationally hard

Shard distribution changes over time, so initially balanced systems eventually become uneven. Systems then need shard migration, rebalancing, live data movement, write redirection and chunk balancing, which introduces consistent hashing and online resharding strategies. One of the hardest operational problems in distributed databases.

### PostgreSQL against MongoDB

PostgreSQL traditionally scales vertically very efficiently, but distributed sharding introduces painful cross shard joins, difficult coordination and operational complexity. This is why PostgreSQL systems usually try batching, coalescing, partitioning and async ingestion before sharding.

MongoDB was designed more naturally around distributed collections, shard routing, document locality and horizontal distribution, so MongoDB sharding often feels operationally more natural for distributed write heavy workloads, denormalised systems and broad ingestion systems. But MongoDB still suffers hotspot chunks, uneven shard utilisation, migration pressure and jumbo chunk problems. Pressure redistributed, not eliminated.

> [!tip] The deepest lesson of this stage
> Distributed systems fail less because of total traffic, and more because of uneven traffic concentration.

---

## Stage 8: replication, multi region writes and consistency pressure

This began when systems finally crossed beyond single region assumptions. Even after Kafka, Redis, sharding and distributed ingestion, systems were still mostly assuming writes happen relatively near each other geographically.

This stage introduced a completely new bottleneck: physical distance itself.

**The core realisation.** Earlier stages optimised throughput, concurrency, mutation pressure and distribution balance. Now systems had to optimise consistency across geography, which is dramatically harder because coordination speed is limited by physics. Cross region communication introduces unavoidable latency.

### Replication

To reduce latency, regional dependency, downtime risk and availability problems, systems introduced replication: multiple copies of data maintained across machines, datacenters and regions.

**The primary replica model.** The primary handles writes, ordering and authoritative durability. Replicas handle reads, geographical locality and failover support. Extremely common in large scale systems.

**Replication lag.** Replicas are never perfectly synchronised instantly, so they temporarily hold stale state, causing stale reads, inconsistent user experience and delayed visibility.

**Eventual consistency reappears.** Different replicas temporarily disagree until synchronisation catches up. Scalability repeatedly pushes systems toward eventual consistency.

### Multi region writes

Read replicas were relatively manageable. Once systems introduced multiple writable regions, complexity exploded: conflicting writes, concurrent updates, ordering ambiguity, clock skew and partition tolerance problems.

**Write conflicts.** The same entity is updated simultaneously from two regions, so systems need conflict resolution: last write wins, application reconciliation, vector clocks, CRDT merges, timestamp ordering.

**Single writer against multi writer.** Multi primary correctness is extremely hard, which is why many systems still prefer a single write leader with distributed read replicas. That reduces conflict complexity, ordering ambiguity and reconciliation problems.

**CAP theorem became real.** Earlier CAP felt abstract; now network partitions became operational reality. During a partition, systems must trade between consistency and availability.

**Quorum systems.** For example 3 replicas with 2 acknowledgments required before a write is considered successful. Quorums balance consistency, durability and availability.

**Clocks became dangerous.** Clocks cannot be fully trusted, because servers drift, skew and disagree. That makes timestamp based ordering dangerous in distributed systems, which introduced Lamport clocks, logical clocks and vector clocks.

**CRDTs.** Conflict free replicated data types safely merge distributed counters, collaborative state and independently updated replicas. They are important for collaborative editing, distributed synchronisation and eventually consistent merges.

**Observability became much harder.** Earlier debugging involved a single database. Now systems have regional lag, stale replicas, split brain risks, quorum failures, partition handling, clock skew and cross region retries.

> [!tip] The deepest lesson of this stage
> Distributed systems are ultimately constrained by coordination across distance. Once systems become globally distributed, consistency itself becomes one of the hardest scalability problems.

---

## Worked example: the viral like counter

A celebrity post with `postId = 123` receiving 2 million likes per minute.

The naive approach is `UPDATE posts SET likes = likes + 1 WHERE id = 123`, and the DB dies immediately due to row contention, fsync pressure, WAL amplification and lock queues.

### The final architecture

```text
Client
   |
API Service
   |
Kafka Producer
   |
Kafka Topic
   |
Kafka Consumers
   |
Redis Aggregation Layer
   |
Batch Flush Workers
   |
PostgreSQL / MongoDB
```

**Step 1, client to API.** `POST /posts/123/like` arrives. The API handles authentication, rate limiting, deduplication, validation, request shaping and idempotency checks. The DB should not directly face internet traffic.

The important design decision: the API does not directly update PostgreSQL, it publishes an event asynchronously.

**Step 2, API to Kafka producer.** The API constructs the event:

```json
{
  "eventId": "e123",
  "postId": 123,
  "userId": 456,
  "action": "LIKE",
  "timestamp": 1710000000
}
```

Communication is a TCP connection using the Kafka binary protocol through a producer library, for example `kafka-clients` in Java, `kafkajs` in Node.js, `sarama` or `confluent-kafka` in Go.

The producer does not know the consumers directly, which is important decoupling. The producer writes to a topic, for example `post-likes`, and Kafka stores the event durably.

The API now finishes quickly because of this. Instead of waiting for DB locks, WAL fsync, replication and aggregation, the API simply says the event was safely accepted into Kafka.

**Step 3, Kafka internals.** Kafka writes events to an append only log, not as random updates. Sequential writes are extremely fast.

```text
partition-0
  offset 1 -> like event
  offset 2 -> like event
  offset 3 -> like event
```

Kafka is optimised for batching, sequential disk I/O, replication and replayability.

**Step 4, Kafka consumers.** Independent services subscribe, for example a `LikeAggregationConsumer`. The consumer maintains a TCP connection to the broker and calls `poll()`, so the broker returns batches. Consumers pull, they are not pushed to, which is an important distinction.

Batch polling matters for the same reason batching always matters: instead of one network round trip per event, you do 1000 events per batch.

**Step 5, consumer to Redis aggregation.** The consumer does not immediately write to the DB. Instead it runs `INCR post:123:likes` inside Redis.

Redis acts as a high speed aggregation buffer: in memory, atomic increment, extremely low latency, absorbs massive write bursts.

Redis now temporarily becomes the source of freshest truth while the DB lags slightly behind. That is the eventual consistency boundary.

**Step 6, batch flush workers.** Separate workers periodically flush Redis aggregates into the DB, for example every 5 seconds or every 50k increments.

```sql
UPDATE posts
SET likes = likes + 12000
WHERE id = 123;
```

or in MongoDB:

```js
db.posts.updateOne(
  {_id: 123},
  {$inc: {likes: 12000}}
)
```

Originally there were 2 million DB writes; now there are a few hundred aggregated writes. The DB load is transformed completely.

**Step 7, the database.** The DB acts as durable long term storage, not a realtime ingestion layer. PostgreSQL stores durable counters, relational consistency, analytics and transactional correctness. MongoDB stores document snapshots, denormalised profile or post state, and scalable retrieval.

### Failures

**Kafka consumer crashes.** No problem. Kafka retains offsets, and the consumer restarts and resumes from its offset. Durability preserved.

**Redis crashes.** Potential aggregation loss. Mitigations: Redis AOF, replaying Kafka events, rebuilding aggregates.

**DB down.** Flush workers pause, Redis accumulates more deltas, the Kafka backlog grows, and the system absorbs pressure temporarily instead of failing outright. That is what the decoupling buys you.

### Why Kafka matters here

| Layer | Concern |
| --- | --- |
| API | low latency |
| Kafka | durable buffering |
| Redis | fast aggregation |
| DB | durable persistence |

The most important realisation: this architecture transforms synchronous per request durable writes into asynchronous batched eventual persistence. That is the heart of write scaling systems.

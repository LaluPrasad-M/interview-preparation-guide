# Write Scaling, Stage by Stage

> [!tldr]
> Reads retrieve shared state; writes modify it. That single difference makes durability, locking, MVCC and coordination the bottlenecks instead of retrieval.

---

## Why writes are harder

Read scaling bottlenecks were mostly repeated retrieval, concurrency pressure and latency amplification.

Write scaling bottlenecks begin with durability, synchronisation, storage coordination, locking, replication and index maintenance. Write systems are fundamentally harder because writes must preserve correctness.

---

## Stage 0: the simple write system

`Client -> API -> PostgreSQL`, used for comment posting, likes, signups, orders, messages and analytics events.

At small scale this architecture is good. The maturity point is: do not prematurely introduce Kafka, sharding, buffering or distributed transactions. PostgreSQL already handles transactions, concurrency, indexes, MVCC and durability extremely well at moderate scale.

**The first realisation.** A write is not merely `INSERT INTO ...`. Internally the DB must acquire locks, allocate transaction metadata, modify heap pages, update indexes, generate WAL, flush durability logs, maintain MVCC visibility and replicate changes. Writes are significantly more expensive than reads.

---

## Stage 1: WAL and durability bottlenecks

**Write ahead logging.** Before modifying the actual data pages, the database first writes the change into the WAL. This exists for crash recovery, durability and corruption prevention. If a crash occurs, the database replays the WAL to recover state.

**The production insight.** At high write throughput the major bottleneck becomes WAL flush latency, not merely CPU usage.

**`fsync()`.** The database eventually forces the OS to flush writes to durable storage. This is necessary because RAM is volatile, the OS page cache is volatile, and crashes lose memory. It introduces storage durability latency as a core bottleneck.

At high scale, the durability guarantees themselves limit throughput. That is the first big mental shift of write scaling.

---

## Stage 2: batching and write amplification

**Why batching appears.** If every write individually performs a WAL append plus an fsync, it is extremely expensive. Batching multiple writes together amortises one fsync across many writes, massively improving throughput.

**The core systems principle.** Amortise fixed costs across many operations. This appears everywhere: databases, Kafka, networking, distributed systems, storage engines.

**The tradeoff.** Batching improves throughput but worsens latency and potentially the durability window. A crash before flush means more data loss is possible. That creates the core tension between throughput and durability guarantees.

**Index write amplification.** During read scaling indexes looked beneficial. During write scaling they become expensive, because every insert or update must modify the heap, update every index, rebalance B trees and generate additional WAL.

Write amplification means one logical write becomes many physical writes.

> [!warning] The biggest indexing realisation
> More indexes improved reads. More indexes reduce write throughput. This is one of the most important database tradeoffs in backend engineering.

**Concurrency pressure begins.** Multiple users update the same shared state: counters, balances, inventory, bidding, wallets. Now the system experiences row locks, contention, waits and transaction conflicts. Writes to the same shared state serialise somewhere, which is one of the deepest distributed systems truths.

---

## Stage 3: lock contention and concurrency collapse

This is the first major transition from storage bottlenecks into coordination bottlenecks.

Multiple writers target the same shared state: wallet balances, seat booking, counters, likes, bidding systems, stock updates, inventory, payment processing.

**The truth this stage teaches.** Write scalability is fundamentally limited by coordination.

### The classic wallet example

Balance is 1000. Two concurrent deductions of 700 and 500 both read 1000 before either writes. That is a race condition.

This teaches something deeper: databases are not merely storage systems. They are shared state coordination systems.

To preserve correctness the database introduces row level locks, so transactions serialise safely and correctness is preserved. But the bottleneck changes again. Earlier the problem was storage throughput; now the problem is waiting.

This reconnects beautifully to read scaling, because once again queues form, retries amplify load, p99 explodes, occupancy increases and connection pools saturate. But now the root cause is shared state coordination instead of read overload.

> [!tip] The recurring pattern
> Many large scale failures are fundamentally queueing failures. Only the source of waiting changes.

### Pessimistic locking

Assumes conflicts are likely and locks immediately. Good for banking, ticket booking, inventory and payment correctness. It introduces waiting, lock queues, occupancy collapse and deadlocks.

### Optimistic locking

Emerged as a reaction to blocking. Assumes conflicts are rare and validates the version during commit, which dramatically reduces waiting. Excellent for profile updates, metadata edits and low conflict systems.

Under high contention, optimistic locking fails differently. Instead of a waiting collapse, the system suffers retry churn collapse, because transactions constantly fail version checks and retry.

The interview insight: the same coordination problem can fail through different amplification mechanisms.

### Hotspotting

Throughput depends not only on volume but also on distribution.

This connects back to Redis hot keys, hot Kafka partitions, viral celebrity traffic, uneven shards and hot DB rows. It is where the whole distributed systems worldview starts becoming unified.

### The evolution so far

```text
Simple writes
-> durability overhead
-> WAL/fsync bottlenecks
-> batching
-> write amplification
-> index maintenance cost
-> shared-state contention
-> lock queues
-> retry amplification
-> hotspotting
```

---

## Stage 4: MVCC pressure

Loosely translated: transaction ID pressure, meaning you maintain as many versions of transaction IDs as are in use. Long running queries such as analytics can add further pressure.

During lock contention we saw that as concurrency increased, readers waited, writers waited, queues formed, retries amplified, p99 exploded and connection pools saturated. If every read and write blocks every other operation, large scale systems become impossible.

So databases evolved MVCC, multiversion concurrency control. Instead of aggressively overwriting data in place, maintain multiple logical versions of rows or documents over time.

This allows readers to continue safely, writers to continue safely, snapshot consistency, and dramatically reduced reader and writer blocking. It was one of the biggest concurrency breakthroughs in database engineering.

**The PostgreSQL realisation.** PostgreSQL handles MVCC through tuple versioning. Updates behave less like overwriting existing bytes and more like appending a newer tuple version. Older tuple versions remain alive temporarily because older transactions may still require older snapshots.

This is why PostgreSQL handles concurrent reads and writes, snapshot isolation, relational consistency and transactional correctness so elegantly. But the elegance came at a cost.

> [!tip] The deepest lesson of this stage
> Scalability almost never removes cost. It redistributes cost. Earlier the system paid through blocking. Now it pays through version churn, cleanup, storage pressure and vacuum overhead.

**Dead tuples became a real system.** Under high update workloads, `UPDATE users SET last_seen = NOW()` executed millions of times. Naively developers imagine the same row being continuously overwritten, but internally PostgreSQL creates many tuple versions, generating dead tuples, WAL amplification, index churn, visibility bookkeeping and storage growth.

**Long running transactions became dangerous.** Old tuple versions cannot be removed while older snapshots may still need them. Hanging analytics queries, forgotten ORM transactions, idle DB connections and long running reports can silently prevent cleanup, causing table bloat, index bloat, scan slowdown, cache inefficiency and vacuum pressure explosion. This is one of the most common real world PostgreSQL production failures, and a very high interview return topic.

**VACUUM became essential.** MVCC and VACUUM are inseparable systems. VACUUM exists because PostgreSQL continuously accumulates obsolete tuple versions; without it storage would grow uncontrollably. But vacuum introduces its own recurring tradeoff: aggressive vacuuming hurts production traffic, weak vacuuming causes bloat explosion.

**Transaction ID pressure.** PostgreSQL visibility tracking depends heavily on transaction IDs. Under massive transaction churn PostgreSQL must prevent transaction ID wraparound, which can trigger aggressive anti wraparound vacuum operations. MVCC is not merely a concurrency feature. It is an ongoing storage maintenance ecosystem.

**MongoDB taught a different lesson.** MongoDB revolves around documents as atomic units, so high update workloads may instead create document relocation, fragmentation, large document rewrites and storage rewrite amplification.

**The final realisation.** The database was still suffering because every write arrived synchronously at database speed, so traffic spikes directly became WAL spikes, MVCC churn, lock pressure, vacuum pressure, replication lag and storage maintenance storms. That naturally led to Kafka, asynchronous buffering, queue decoupling and event driven ingestion.

---

## Stage 5: async ingestion and write path optimisation

Stage 5 began the moment we realised Kafka did not eliminate database pressure.

The architecture evolved from `Client -> API -> Database` into `Client -> API -> Kafka -> Consumers -> Database`.

Kafka solved burst smoothing, temporal decoupling, API responsiveness and retry isolation. But the database still eventually had to absorb writes, counters, updates and mutations.

> [!tip] The core realisation of this stage
> Scalable systems must reduce mutation frequency before persistence.

Initially systems assumed every event must immediately mutate durable storage, which caused WAL pressure, MVCC churn, lock contention, replication lag, vacuum pressure and hot row bottlenecks. So systems evolved toward buffering, aggregation, coalescing and append only ingestion.

### Kafka's role

Kafka became a durable traffic shock absorber, decoupling the traffic arrival rate from the database processing rate. It transformed violent burst traffic into controlled sustained throughput.

Kafka solved burst absorption, retry buffering, asynchronous ingestion and temporal decoupling. But Kafka did not reduce the total logical workload, which is what introduced Redis.

### Redis as a mutation aggregation layer

Redis was not introduced as a generic cache. Redis became a high speed mutable aggregation layer.

```text
Client
-> API
-> Kafka
-> Consumers
-> Redis aggregation
-> Batch flush workers
-> Database
```

Redis absorbed hot counters, rapid increments, temporary mutations and aggregation pressure, which dramatically reduced DB updates, WAL generation, MVCC churn and index maintenance overhead.

### Write coalescing

Instead of 1 million events becoming 1 million DB mutations, systems evolved toward 1 million events becoming a small number of aggregated writes.

Instead of `UPDATE likes = likes + 1` per request, systems perform a Redis `INCR` and periodically flush aggregated deltas. This was one of the biggest write scaling breakthroughs.

### Eventual consistency

Once Kafka, Redis buffering and async flush pipelines are in place, the database stops being the instant truth source and becomes eventually materialized durable state. Live counters and durable storage might temporarily diverge, which becomes acceptable because scalability required relaxing immediate synchronisation.

### Append only thinking

Instead of constantly mutating rows, systems evolved toward storing immutable events. Instead of `UPDATE likes = likes + 1`, store `{"event": "POST_LIKED"}`.

This reduced hot row contention, lock amplification and mutation coordination pressure.

### Kafka evolved into a durable event log

Initially Kafka was a traffic buffer. Later it became durable replayable event memory, which mattered because Redis could fail, projections could corrupt and consumers could crash. Kafka allowed replay, reconstruction, aggregate rebuilding and projection recovery.

### CQRS and materialized projections

Systems realised read optimisation and write optimisation are fundamentally different problems, so the write side optimised for ingestion throughput and the read side for query performance. The database increasingly became a materialized projection layer generated asynchronously from event streams.

### Stream compaction

As event streams grew massively, systems introduced log compaction, because retaining every mutation forever became expensive. Compaction reduced storage growth, replay cost and retention overhead.

Systems optimised by reducing pressure rather than blindly distributing it.

### Redis introduced new bottlenecks

Redis solved mutation frequency, aggregation pressure and hot counter updates. But Redis itself became a hot mutable state bottleneck for celebrity counters, viral posts, hot keys and massive INCR traffic, producing Redis CPU saturation, single thread bottlenecks, replication lag and hot key pressure.

Every scaling optimisation creates new pressure elsewhere. This recurring law keeps appearing.

> [!tip] The defining sentence of this stage
> Scalable write systems succeed not because they write faster, but because they mutate durable storage less frequently.

---

## Stage 6: idempotency, retries and distributed write correctness

This stage began the moment asynchronous systems introduced retries, replay, duplicate delivery, consumer crashes and acknowledgment ambiguity. The problem changed from performance scaling into distributed correctness.

**The core realisation.** In distributed systems delivery is easy, but correctness under retries is hard.

Suppose a consumer successfully updates the DB but crashes before the ACK. Kafka redelivers the event, and now duplicate orders, double payments, duplicate emails and inconsistent state become possible.

That introduced idempotence: repeating the same operation should not change the final result incorrectly.

**Idempotency keys.** Request IDs, deduplication tables, unique constraints, replay safe writes. For example `UNIQUE(payment_request_id)`. This became one of the most practical distributed correctness patterns.

**The exactly once myth.** True global exactly once processing is nearly impossible under failures, because ACKs can fail, networks partition, consumers crash, and ambiguity always exists. Real systems usually implement at least once delivery plus idempotent processing.

**Ordering problems.** Replay ordering, out of order events, partition ordering and stale event overwrites, which makes Kafka partition keys, sequencing and ordering guarantees extremely important.

---

## Stage 7: partitioning, sharding and hotspot management

This began once we exhausted almost every single node write optimisation: Kafka buffering, Redis aggregation, write coalescing, batching, append only ingestion, CQRS and materialized projections.

All those dramatically reduced synchronous pressure, mutation frequency, WAL amplification, lock contention and MVCC churn. But eventually a hard physical reality appeared: one machine cannot scale forever. CPU, memory, disk bandwidth, WAL throughput and network are all finite.

That is the birth of partitioning and sharding.

> [!tip] The deepest realisation of this stage
> Scalability problems are often distribution problems. Not merely more traffic, but uneven traffic.

### Partitioning against sharding

Partitioning broadly means splitting data logically, sometimes still on the same physical machine, for example `orders_2024`, `orders_2025`, `orders_2026`. It improves query pruning, maintenance, archival operations, vacuum locality and index locality. Especially important in PostgreSQL for very large relational tables.

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

**CRDTs.** Conflict free replicated data types safely merge distributed counters, collaborative state and independently updated replicas. Important for collaborative editing, distributed synchronisation and eventually consistent merges.

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

This is powerful because the API now finishes quickly. Instead of waiting for DB locks, WAL fsync, replication and aggregation, the API simply says the event was safely accepted into Kafka.

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

Originally 2 million DB writes; now a few hundred aggregated writes. The DB load is transformed completely.

**Step 7, the database.** The DB acts as durable long term storage, not a realtime ingestion layer. PostgreSQL stores durable counters, relational consistency, analytics and transactional correctness. MongoDB stores document snapshots, denormalised profile or post state, and scalable retrieval.

### Failures

**Kafka consumer crashes.** No problem. Kafka retains offsets, and the consumer restarts and resumes from its offset. Durability preserved.

**Redis crashes.** Potential aggregation loss. Mitigations: Redis AOF, replaying Kafka events, rebuilding aggregates.

**DB down.** Flush workers pause, Redis accumulates more deltas, the Kafka backlog grows, and the system absorbs pressure temporarily. A beautiful decoupling property.

### Why Kafka matters here

| Layer | Concern |
| --- | --- |
| API | low latency |
| Kafka | durable buffering |
| Redis | fast aggregation |
| DB | durable persistence |

The most important realisation: this architecture transforms synchronous per request durable writes into asynchronous batched eventual persistence. That is the heart of write scaling systems.

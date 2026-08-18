# Write Scaling, Stage by Stage

> [!tldr]
> Reads retrieve shared state; writes modify it. That single difference makes durability, locking, [[multi-version-concurrency-control|MVCC]] and coordination the bottlenecks instead of retrieval.

---

## The parts

| Note | Covers |
| --- | --- |
| [[write-path-basics]] | [[write-ahead-log|WAL]], [[fsync]], batching, lock contention and the first bottlenecks |
| [[sharding-and-scale]] | partitioning, sharding, hotspot management and the viral like counter |

---

## Stage 4: MVCC pressure

In loose translation, this is transaction ID pressure: you maintain as many versions of transaction IDs as are in use. Long running queries such as analytics can add further pressure.

During lock contention we saw that as concurrency increased, readers waited, writers waited, queues formed, retries amplified, p99 exploded and connection pools saturated. If every read and write blocks every other operation, large scale systems become impossible.

So databases evolved MVCC, multiversion concurrency control. Instead of aggressively overwriting data in place, maintain multiple logical versions of rows or documents over time.

This allows readers to continue safely, writers to continue safely, snapshot consistency, and dramatically reduced reader and writer blocking. It was one of the biggest concurrency breakthroughs in database engineering.

**The PostgreSQL realisation.** PostgreSQL handles MVCC through tuple versioning. Updates behave less like overwriting existing bytes and more like appending a newer tuple version. Older tuple versions remain alive temporarily because older transactions may still require older snapshots.

This is why PostgreSQL can give you concurrent reads and writes, snapshot isolation, relational consistency and transactional correctness all at once. That combination came at a cost.

> [!tip] The deepest lesson of this stage
> Scalability almost never removes cost. It redistributes cost. Earlier the system paid through blocking. Now it pays through version churn, cleanup, storage pressure and vacuum overhead.

**Dead tuples became a real system.** Under high update workloads, `UPDATE users SET last_seen = NOW()` executed millions of times. Developers naively imagine the same row being continuously overwritten, but internally PostgreSQL creates many tuple versions, generating dead tuples, WAL amplification, index churn, visibility bookkeeping and storage growth.

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

### [[cqrs|CQRS]] and materialized projections

Systems realised read optimisation and write optimisation are fundamentally different problems, so the write side optimised for ingestion throughput and the read side for query performance. The database increasingly became a materialized projection layer generated asynchronously from event streams.

### Stream compaction

As event streams grew massively, systems introduced log compaction, because retaining every mutation forever became expensive. Compaction reduced storage growth, replay cost and retention overhead.

Systems optimised by reducing pressure rather than blindly distributing it.

### Redis introduced new bottlenecks

Redis solved mutation frequency, aggregation pressure and hot counter updates. But Redis itself became a hot mutable state bottleneck for celebrity counters, viral posts, [[hot-key|hot keys]] and massive INCR traffic, producing Redis CPU saturation, single thread bottlenecks, replication lag and hot key pressure.

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

**Ordering problems.** These are replay ordering, out of order events, partition ordering and stale event overwrites, which makes Kafka partition keys, sequencing and ordering guarantees extremely important.

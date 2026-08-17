# The NFR Decision Table

> [!tldr]
> Read it row wise in an interview, once you know your dominant non functional requirement. Revise it column wise while studying.

---

## The table

| Dominant NFR | What must not fail | Typical systems | Write path | Read path | Database, and why | API style | Service style | Messaging | Caching | Workflow | Real product |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Strong consistency plus low latency | correctness | payments, wallets, inventory locks | sync, transactional, single writer | direct DB or cache | Postgres or MySQL, for ACID and isolation | sync REST or gRPC | modular monolith or few services | Kafka only after commit | Redis, read through only | avoid retries | Stripe, payment authorization |
| Low latency plus high availability plus eventual consistency | speed and uptime | likes, comments, presence, counters | local sync writes | local reads | DynamoDB or Cassandra, for local writes and async replication | sync, local only | stateless, region isolated | Kafka or streams for replication | heavy regional caching | rare | Instagram likes, WhatsApp presence |
| High throughput plus high availability | durability | event ingestion, analytics | async, buffered | eventually consistent | Kafka as truth plus Cassandra or DynamoDB | fire and ack APIs | microservices with consumer groups | Kafka mandatory | minimal | no | LinkedIn activity pipeline |
| Ultra low latency plus read heavy scale | fast reads | feeds, timelines, catalogs | async fan out | cache first | Redis or DynamoDB, for constant time reads | sync reads, async writes | read and write separated services | Kafka for fan out | aggressive, Redis plus [[cdn|CDN]] | no | Twitter home timeline |
| High availability plus global scale plus eventual consistency | always writable | messaging, social graphs | local writes, async global sync | local reads | DynamoDB Global or Cassandra multi DC | local sync APIs | regional microservices | Kafka for cross region sync | regional caches | no | WhatsApp message delivery |
| Scalability plus team autonomy | team velocity | large SaaS platforms | service owned writes | service owned reads | a database per service, any type | REST or gRPC plus async events | true microservices | Kafka for integration events | per service | no | Netflix service ecosystem |
| Long running reliability plus retries | completion | orders, onboarding, trip lifecycle | step wise, durable | query workflow state | workflow engine internal state | API triggers a workflow | microservices coordinated by the workflow | Kafka for signals and events | optional | workflow engine mandatory | Uber trip lifecycle |
| Search heavy plus flexible queries | query power | product search, log search | index writes async | query the index | Elasticsearch, for the inverted index | sync search APIs | search as an isolated service | Kafka for indexing | query cache | no | Amazon product search |
| Analytics and reporting, [[oltp-and-olap|OLAP]] | insight accuracy | dashboards, BI | batch or stream ingest | analytical queries | BigQuery or Snowflake, columnar | async ingestion | a separate analytics stack | Kafka into [[etl|ETL]] | no | no | Netflix viewing analytics |

---

## The five combinations, in depth

The table is the summary. These are the five that come up most, with the databases explicitly rejected and why.

### 1. Strong consistency plus low latency

Money, inventory, locks, balances. Correctness beats availability, p99 under 100 ms.

**The database pressure.** Atomic writes, isolation, rollbacks, strict ordering. Only one family fits.

**Chosen.** PostgreSQL or MySQL, for ACID transactions, serialisable or repeatable read isolation, and strong constraints.

**Explicitly rejected.** DynamoDB, because it is eventually consistent by default. Cassandra, because it has no multi row transactions. MongoDB, because of historically weaker transactional guarantees.

```text
Client -> API Service -> Transaction Boundary -> Primary RDBMS -> Response

Optional read optimisation:
Client -> API -> Redis (read-through) -> RDBMS
```

**The stack.** Postgres primary plus read replicas, Redis for read only optimisation, idempotency via DB unique constraints, Kafka post commit only. No workflow engine, because retries are dangerous for money.

**Why it is forced.** The RDBMS guarantees correctness, a single writer avoids conflicts, a sync API ensures immediate truth, and publishing to Kafka only after commit avoids double spend.

**Real product.** Stripe, whose ledger is strongly consistent, every balance update transactional, with Kafka used only for downstream effects.

> [!tip] The lock-in insight
> If you choose an RDBMS, you are choosing consistency over availability.

### 2. High throughput plus high availability

Event ingestion, logs, analytics pipelines. Durability beats immediate consistency.

**The database pressure.** Append only writes at very high volume with no read after write requirement. An RDBMS collapses here.

**Chosen.** Kafka as the log and source of truth, Cassandra or DynamoDB for the hot path, S3 plus an OLAP store for the cold path.

```text
Producers -> Ingestion API -> Kafka (truth) -> Stream Processing -> Cassandra / S3
```

**The stack.** A Go or Node ingress API, Kafka, Kafka Streams or Flink for processing, Avro plus a schema registry. No RDBMS, because it is the write bottleneck.

**Why it is inevitable.** Kafka absorbs spikes, Cassandra scales linearly, writes never block, and eventual consistency is acceptable.

**Real product.** LinkedIn, where Kafka is the backbone, Cassandra stores activity data, and the RDBMS holds only metadata.

> [!tip] The lock-in insight
> Choosing Cassandra means you have accepted eventual consistency forever.

### 3. Ultra low latency plus read heavy scale

Feeds, timelines, catalogs. Reads outnumber writes 1000 to 1, availability beats freshness, p99 read latency under 50 ms.

**The database pressure.** Reads must be constant time, avoid joins and be cacheable. Normalised databases fail here.

**Chosen.** Redis or Memcached, DynamoDB or Cassandra denormalised, Elasticsearch where search is involved.

```text
Write path: User Action -> Kafka -> Fanout Service -> Feed Store (KV / Redis)
Read path:  Client -> CDN -> Redis -> Feed Store
```

**The stack.** Kafka, Flink or Kafka Streams, Redis or DynamoDB as the feed store, Redis plus CDN caching. No on demand joins, and no RDBMS on the read path.

**Why it works.** Writes pay the complexity, reads are precomputed, and the cache hit rate is huge.

**Real product.** Twitter, with the home timeline stored as precomputed lists, Redis backed timeline caches and async fanout.

> [!tip] The lock-in insight
> Once you denormalise, you cannot go back without a redesign.

### 4. Global availability plus eventual consistency

Messaging, likes, presence. Always writable, multi region, partition tolerant.

**The database pressure.** Writes must succeed locally and never wait for global consensus. Strongly consistent databases break global availability.

**Chosen.** DynamoDB Global Tables, Cassandra multi datacenter, or CosmosDB.

```text
Region A             Region B
 API -> DB            API -> DB
      \                /
       Async Replication
```

**The stack.** Async replication streams, conflict resolution by [[last-write-wins|last write wins]] or version vectors, regional Redis. No distributed transactions and no global locks.

**Real product.** WhatsApp, where messages are written locally, delivered asynchronously, and synced across devices eventually.

> [!tip] The lock-in insight
> Global databases force you to design conflict resolution upfront. See [[multi-region-cart]].

### 5. Long running workflows plus reliability

Orders, onboarding, trip lifecycle. Steps span minutes or hours, partial failure is normal, recovery must be automatic.

**The database pressure.** Workflow state must survive crashes, resume deterministically and avoid duplicate execution. Traditional databases are painful here.

**Chosen.** A workflow engine's own durable state, backed internally by Cassandra or MySQL.

```text
API -> Workflow Engine
        -> Service A (DB A)
        -> Service B (DB B)
        -> Service C (DB C)
```

**The stack.** The engine as orchestrator, service owned databases, engine managed retries, durable workflow history. No DIY retry logic.

**Real product.** Uber, where trip creation, driver matching, pricing and payment settlement are all long running, which makes a workflow engine mandatory.

> [!tip] The lock-in insight
> If retries matter, state must live outside your service. See [[workflow-engines]].

---

## The final mental map

```text
Strong consistency      -> RDBMS
High write throughput   -> Kafka + Cassandra
Low latency reads       -> Redis / DynamoDB
Global availability     -> DynamoDB Global / Cassandra
Long workflows          -> a workflow engine
Search heavy reads      -> Elasticsearch
Analytics               -> OLAP (BigQuery / Snowflake)
```

This is not preference. It is constraint satisfaction.

---

## Async fanout against async buffered

These two get confused constantly, and they solve different problems.

### Async fanout

One incoming request or event is asynchronously propagated to many downstream consumers. The caller does not wait for the downstream work.

```text
Client -> API -> Event / Message
                    |-> Service A
                    |-> Service B
                    +-> Service C
```

**Use cases.** Social feed updates, notifications by email, push and SMS, cache invalidation across services, audit logging plus analytics plus ML pipelines.

**Characteristics.** High scalability, loose coupling, parallel execution, and tolerance of partial failure, since one consumer can fail without breaking the others.

**The example.** A user posts. The feed service updates timelines, the notification service alerts followers, the analytics service logs engagement, and the search index updates, all triggered asynchronously.

**Pros.** Fast response time, easy to add or remove consumers, great for event driven systems.

**Cons.** Eventual consistency, harder debugging, possible ordering and duplication issues.

### Async buffered

Requests are placed into a buffer and processed later at a controlled rate. This is about absorbing spikes and smoothing load, not branching.

```text
Client -> API -> Queue/Buffer -> Worker(s) -> Service
```

**Use cases.** Background jobs, video and image processing, email sending, payment retries, batch writes.

**Characteristics.** It decouples producer from consumer speed, protects downstream systems, enables [[backpressure]], and is usually but not always FIFO.

**The example.** A user uploads a video. The API responds immediately, the video is queued, and workers transcode in the background.

**Pros.** Handles traffic bursts, prevents overload, easy retry semantics.

**Cons.** Added latency, queue management complexity, possible backlog buildup.

### Side by side

| Aspect | Async fanout | Async buffered |
| --- | --- | --- |
| Primary goal | parallelise work | smooth load |
| Pattern | one to many | one to queue to one or many |
| Latency | low for the caller | higher |
| Handles spikes | not by itself | yes |
| Backpressure | weak | strong |
| Failure isolation | consumer level | worker level |

# Scaling from Zero to Millions of Users

> [!tldr]
> Nine stages from a single server monolith to a fully distributed system. Each stage exists because the previous one broke.

---

## Stage 0 to 1: single server monolith

```text
Client -> Web Server
              |- App Logic
              +- Database
```

Everything runs on one machine. Simple to build and deploy, and it works for few users and low traffic.

**Terminology.** A monolith bundles UI, business logic and DB tightly together. Vertical scaling, or scaling up, means increasing the CPU and RAM of the same server.

**Bottlenecks.** CPU saturation, memory limits, and a single point of failure.

**The line to say.** At very low traffic, a single server monolith is acceptable due to simplicity, but it does not scale or provide fault tolerance.

---

## Stage 2: separate web server and database

```text
Client -> Web Server -> Database Server
```

**Why.** The DB is usually the first bottleneck, and this allows independent scaling of the DB and the app.

**New terms.** Two tier architecture. Read and write contention, meaning multiple requests fighting for DB access. Connection pooling, reusing DB connections.

**Improvement.** The app can scale without touching DB hardware.

---

## Stage 3: load balancer plus multiple app servers

```text
Client
   |
Load Balancer
   |
App Server 1
App Server 2
App Server 3
   |
Database
```

**Core concepts.** Horizontal scaling, or scaling out, adds more servers. Stateless servers store no user data in memory. Load balancing algorithms include round robin, least connections and IP hash.

**Key terminology.** Sticky sessions are bad for scaling. Statelessness is mandatory at scale.

**The line to say.** To scale horizontally, application servers must be stateless, otherwise load balancing becomes ineffective.

---

## Stage 4: database replication for read scaling

```text
           -> Read Replica 1
App -> Master DB
           -> Read Replica 2
```

Writes go to the primary, reads go to the replicas.

**High value terminology.** Replication lag is the delay between primary and replica. Eventual consistency. Read scalability.

| Benefit | Cost |
| --- | --- |
| more read throughput | slightly stale reads |
| fault tolerance | sync complexity |

---

## Stage 5: caching layer

```text
Client
   |
App Server
   |
Cache (Redis)
   | (cache miss)
Database
```

**Why cache.** The DB is expensive and most requests are read heavy.

**Key terms.** Cache hit and cache miss, TTL, eviction policy (LRU, LFU), hot data.

**Strategies.** Read through cache, write through cache, and cache aside (lazy loading), which is the most common.

**The line to say.** Cache is introduced to reduce database load and latency, especially for hot, frequently accessed data.

---

## Stage 6: content delivery network

A CDN is a network of geographically dispersed servers used to deliver static content. CDN servers cache static content like images, videos, CSS and JavaScript files.

```text
User -> CDN Edge -> Origin Server
```

**Used for.** Images, CSS and JS, videos.

**New terminology.** Edge server, origin server, cache invalidation, geo replication.

**Benefits.** Reduced latency, reduced origin server load, better global performance.

Dynamic content caching is a newer concept: it enables caching of HTML pages based on request path, query strings, cookies and request headers. Most courses focus on static content.

---

## The stateless web tier, in detail

To scale the web tier horizontally, move state such as user session data out of the web tier. Good practice is to store session data in persistent storage such as a relational database or NoSQL, so each web server in the cluster can access state data from the database. That is a stateless web tier.

### Stateful architecture

A stateful server remembers client data from one request to the next. A stateless server keeps no state information.

In a stateful setup, user A's session data and profile image are stored in Server 1. To authenticate user A, HTTP requests must be routed to Server 1. If a request is sent to Server 2, authentication would fail because Server 2 does not contain user A's session data. Similarly all requests from user B must go to Server 2, and all from user C to Server 3.

The issue is that every request from the same client must be routed to the same server. This can be done with sticky sessions in most load balancers, but it adds overhead. Adding or removing servers becomes much harder, and handling server failures is challenging.

### Stateless architecture

HTTP requests from users can be sent to any web server, which fetches state data from a shared data store. State data lives in the shared store and is kept out of the web servers. A stateless system is simpler, more robust and more scalable.

The shared data store could be a relational database, Memcached, Redis or NoSQL. NoSQL is often chosen because it is easy to scale.

Autoscaling means adding or removing web servers automatically based on traffic load. Once state data is removed from the web servers, autoscaling of the web tier is easily achieved.

Once the site attracts significant international traffic, supporting multiple data centers becomes crucial for availability and user experience across wider geographical areas.

---

## Stage 7: asynchronous processing with queues

```text
Client -> App -> Queue -> Worker
```

**Use cases.** Emails, notifications, image processing, analytics.

**Key terms.** Message queue, producer and consumer, backpressure, at least once delivery.

**The line to say.** Queues decouple slow or non critical work from user facing request paths.

---

## Stage 8: database sharding for write scaling

```text
Shard 1 -> User 1-1000
Shard 2 -> User 1001-2000
Shard 3 -> User 2001-3000
```

**Critical terms.** Shard key, horizontal partitioning, hot shard, re sharding.

| Pro | Con |
| --- | --- |
| massive write scaling | complex queries |
| smaller datasets | cross shard joins are hard |

---

## Stage 9: observability and reliability

**The three pillars.** Logs tell you what happened. Metrics tell you how often and how much. Traces tell you the request flow.

**Key terms.** SLI, SLO and SLA. Health checks. Circuit breaker. Auto scaling.

---

## The final evolution diagram

```text
Users
 |
CDN
 |
Load Balancer
 |
Stateless App Servers
 |
Cache -> DB (Sharded + Replicas)
 |
Message Queue -> Workers
 |
Monitoring / Logs / Alerts
```

> [!tip] The one line summary to memorise
> We start with a monolith, then introduce horizontal scaling via load balancers, cache for read performance, replication for read scaling, sharding for write scaling, CDNs for static content, queues for async processing, and observability for reliability.

---

## What breaks first in horizontal scaling

Database connections break.

**What breaks.** DB connection limits, slow queries, DB crashes under load.

**Why.** Each new instance opens its own DB connections. One server means 50 connections, which is fine. Twenty servers means 1000 connections, and most databases have hard connection limits.

**How to fix it.** Connection pooling (HikariCP, PgBouncer), lower per instance connection counts, read replicas, caching reads with Redis, moving to async and background processing.

**The interview insight.** The database often becomes the first bottleneck in horizontal scaling.

---

## The scaling ladders by workload

### Read heavy systems

Examples: news websites, e-commerce catalogs, movie databases, product search, profile views. Traffic is roughly 95 percent reads and 5 percent writes.

**SQL read scaling.**

| Scale | Solution | Why |
| --- | --- | --- |
| Normal | single DB | simple |
| 5x | indexes | faster queries |
| 10x | read replicas | offload reads |
| 100x | Redis | memory speed reads |
| 1000x | CDN plus Redis plus multiple replicas | the DB is rarely hit |

The ladder: primary DB, then indexes, then read replicas, then Redis, then CDN.

**MongoDB read scaling.**

| Scale | Solution | Why |
| --- | --- | --- |
| Normal | single node | simple |
| 5x | indexes | faster reads |
| 10x | secondary reads | replica set |
| 100x | Redis | reduce DB load |
| 1000x | Redis plus many secondaries | massive read scaling |

The ladder: Mongo, then indexes, then replica set, then Redis, then many secondaries.

**The interview risk here.** Replication lag. A recent write may not be visible on a replica.

### Write heavy systems

Examples: payments, telemetry, IoT, event tracking, audit logs. Traffic is roughly 10 percent reads and 90 percent writes.

**SQL write scaling.**

| Scale | Solution | Why |
| --- | --- | --- |
| Normal | single DB | simple |
| 5x | batch writes | fewer DB trips |
| 10x | Kafka or SQS | smooth spikes |
| 100x | partitioning | smaller indexes |
| 1000x | sharding | horizontal write scaling |

The ladder: primary DB, batch writes, queue, partitioning, sharding.

**MongoDB write scaling.**

| Scale | Solution | Why |
| --- | --- | --- |
| Normal | single node | simple |
| 5x | `bulkWrite()` | efficient writes |
| 10x | Kafka or SQS | async processing |
| 100x | sharding | native horizontal scale |
| 1000x | more shards | distributed writes |

**The interview risk here.** Hot shard from a bad shard key such as `createdAt` or `timestamp`, so all writes go to one shard.

### Read and write heavy systems

Examples: ride hailing, large e-commerce, messaging, food delivery, trading platforms. Millions of both reads and writes.

**SQL.** Normal is app to primary DB. At 5x, query optimisation, indexes and connection pooling. At 10x, read replicas, with reads on replicas and writes on the primary. At 100x, Redis for reads and Kafka or SQS for writes. At 1000x, partitioning, sharding and multiple replicas per shard:

```text
Shard1
 |- Primary
 |- Replica
 +- Replica

Shard2
 |- Primary
 |- Replica
 +- Replica
```

The ladder: indexes, read replicas, Redis, queue, partitioning, sharding, sharded replicas.

**MongoDB.** Normal is app to Mongo. At 5x, indexes and query optimisation. At 10x, a replica set with a primary and secondaries. At 100x, Redis for reads and a queue for writes. At 1000x, a sharded cluster where each shard is itself a replica set.

The ladder: indexes, replica set, Redis, queue, sharding, sharded replica sets.

### The cheat sheet

| Problem | SQL | Mongo |
| --- | --- | --- |
| Read scaling | read replica | secondary reads |
| Write scaling | partitioning then sharding | sharding |
| Cache | Redis | Redis |
| Write burst | Kafka or SQS | Kafka or SQS |
| Huge data | partitioning | sharding |
| Read and write scale | sharded replicas | sharded replica sets |
| Archiving | partition drop | archive collection |
| Read latency | Redis or CDN | Redis |
| Write latency | queue | queue |

---

## The scaling hierarchy, in order

Never jump to sharding first. If you jump directly to sharding, the interviewer will think you are shallow.

1. Query optimisation
2. Index optimisation
3. Connection pool tuning
4. Caching
5. Read replicas
6. Denormalisation and materialized views
7. Partitioning
8. Async processing via Kafka
9. CQRS, if needed
10. Sharding, as a last resort

---

## Every scaling strategy, and what it scales

| Strategy | What it scales |
| --- | --- |
| Vertical scaling | a bigger machine |
| Read replicas | read throughput |
| Redis caching | reduces DB hits |
| Queue buffering | smooths bursts |
| Batching | reduces transaction overhead |
| Async processing | shortens request lifetime |
| CQRS | separates read and write load |
| Materialized views | precomputes expensive reads |
| Denormalisation | reduces joins |
| Partitioning and sharding | write scalability |
| Multi region replication | geographic scaling |

---

## Handling geography induced latency

| Technique | What it does |
| --- | --- |
| Geo partitioning | each region owns local data to avoid cross region writes |
| Local read replicas | serve reads from the nearest region for low latency |
| Async replication | faster writes, but eventual consistency and stale reads are possible |
| CDN plus edge caching | push frequently accessed content closer to users |
| Single writer per region | reduce cross region coordination |
| Quorum based systems | balance consistency against latency with read and write quorums |
| Regional inventory allocation | prevent global coordination bottlenecks |
| Request routing | route users to the nearest healthy region |
| Conflict free models (CRDTs) | allow concurrent geo updates for mergeable data |
| Write locality optimisation | keep writes near the originating users or services |

**The core tradeoff.** Lower latency against stronger consistency. Global strong consistency always increases latency due to network round trips and speed of light limits.

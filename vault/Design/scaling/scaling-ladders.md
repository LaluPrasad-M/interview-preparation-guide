# Scaling Ladders by Workload

> [!tldr]
> Different workloads scale differently: read heavy systems climb the caching ladder, write heavy systems must shard, and mixed workloads combine both strategies.

Part of [[zero-to-millions]].

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

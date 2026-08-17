# Replication, Partitioning and Sharding

> [!tldr]
> Three words people use interchangeably that solve three different problems. Replication scales reads, partitioning shrinks scans, sharding scales writes and storage.

---

## Replication

A full copy of the database, with the same data on multiple nodes.

**Purpose.** Scale reads, high availability, failover.

> [!warning] The key insight
> Replication improves read throughput. It does not increase write capacity, and it does not reduce dataset size.

> [!tip] The interview line
> Replication duplicates data for availability and read scaling, not for storage distribution.

---

## Partitioning

Splitting a large table into smaller physical tables that logically appear as one table.

```sql
CREATE TABLE orders (...) PARTITION BY RANGE (created_at);
```

**Purpose.** Faster scans via partition pruning, smaller indexes per partition, better maintenance such as vacuum and archival.

> [!warning] Partitioning is not horizontal scaling
> By default it is not scaling across machines. It is usually within one DB node.

---

## Sharding

Distributing data across multiple machines, where each shard contains a subset of the data.

In MongoDB this is built in. In SQL it is usually application managed, or handled via Citus or Vitess.

**Purpose.** Scale writes, scale storage, true horizontal scaling.

---

## The most important insight

Sharding only works if most queries include the shard key.

If a query does not contain the shard key, the router performs a scatter gather: it sends the query to all shards, each processes it, and the results are merged, sorted and returned. That kills scalability.

It is worse than a single full table scan, because it becomes a parallel full scan across all shards, adding network overhead, multiplied CPU, and merge cost.

> [!tip] The interview ready explanation
> If the shard key does not align with dominant query patterns, the system performs scatter gather queries, defeating the purpose of horizontal scaling.

---

## Hot shards

If you shard by city and Delhi has 80 percent of traffic, the Delhi shard is overloaded and the others sit idle. That happens because the shard key distribution is skewed.

**Fixes.** A composite shard key such as `(city, restaurant_id)`. A hashed shard key. Splitting the hot partition further. Regional clusters.

---

## The scaling hierarchy

Never jump to sharding first. If you do, the interviewer thinks you are shallow.

1. Query optimisation
2. Indexing
3. Caching, Redis or CDN
4. Read replicas
5. Partitioning
6. Sharding

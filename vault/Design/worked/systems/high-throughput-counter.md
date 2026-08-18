# High Throughput Counter Service

> [!tldr]
> Page view counters at a million increments per second. The whole design follows from one decision: the database cannot be on the write path, so Redis absorbs the writes and a background job folds them into the database in batches.

---

## The problem

Every page view increments a counter for that page.
Peak load is around one million increments per second, reads are roughly ten times more frequent than writes, and the count shown to users may lag reality by a few seconds.
Losing a small number of increments during a crash is acceptable.

**The objective.** Serve a view count per page under very high write throughput, with low latency and high availability, accepting eventual consistency.

---

## The key insight

A relational row update per view does not scale to a million writes per second.
Each one takes a row lock, writes to the log, and competes with every other writer for the same row on a popular page.
Contention, locks and disk I/O put a ceiling far below the target long before CPU does.

So the roles split:

| Layer | Role |
| --- | --- |
| Redis | absorbs every increment, atomically, in memory |
| Database | durable source of truth, written in batches, never per request |
| Background aggregator | moves counts from one to the other on a timer |

---

## The counter key

The entity being counted is the page, so the key is `page_id`.
Sharding by `user_id` is the instinct to resist: increments for one page have to end up aggregated together, and a user based key scatters them across the keyspace where nothing can add them up cheaply.

That correct key immediately creates the next problem.

---

## The hot key problem, and the fix

A viral page taking 200,000 views per second sends all of them to one Redis key, which lives on exactly one node in the cluster.
That node saturates while the rest sit idle, and adding nodes does not help, because the key does not get smaller or move, see [[redis-cluster]].

The fix is the sharded counter from [[redis-use-cases]]: one page becomes `page:123:shard:1` through `page:123:shard:N`, each write picks one shard, and a read sums them all.
Those N keys hash to different slots, so the writes for one page land on different nodes instead of one.

---

## Redis usage, precisely

- Redis Cluster, keys distributed by hash slot, so `(page_id, shard_id)` decides the node.
- `INCR` is atomic on its own, so no locks and no Lua script are needed for the write path.
- Replicas exist for failover, not for write scaling, see [[redis-internals]].

Redis gives atomic increments. It does not give durability, which is what the database is for.

---

## The read path

A read has to add the durable part to the part still sitting in memory:

```text
total = db_count + sum(page:123:shard:1 .. page:123:shard:N)
```

Reads are far more frequent than writes, so the aggregated total is worth caching for one to five seconds.
That single short lived cache entry turns N shard reads per request into N shard reads per few seconds.

---

## Async persistence

A background job runs every few seconds and, per page:

1. Reads the shard counters.
2. Sums them into one delta.
3. Adds that delta to the database row.
4. Resets the shard counters it just read.

Batching is the point.
One database write per page per interval instead of one per view, and the writes are sequential rather than a storm of contending updates on the same row.

---

## Failure handling

| Failure | Behaviour |
| --- | --- |
| Redis crashes before a sync | the increments since the last sync are lost, which the requirements allow |
| Database is down | Redis keeps accepting increments, the aggregator retries later, nothing user visible breaks |
| Aggregator crashes mid sync | the danger is double counting, so the sync has to be idempotent, tracking a version or offset per page rather than blindly adding again, see [[idempotency]] |

The mid sync case is the one interviewers push on: reset-after-read is not atomic with the database write, so the job needs to know what it already applied.

---

## Consistency guarantees, stated plainly

- Eventual consistency, counts can lag by a few seconds.
- Slight undercounting is possible after a Redis failure.
- Availability is chosen over exactness, which is defensible for view counts and would not be for money, see [[billing-ledger]].

---

## The architecture

```text
Clients
   |
Counter API
   |
Redis Cluster  (sharded counters per page)
   |
Background aggregator  (every few seconds)
   |
Database  (durable count)
```

> [!tip] The one liner
> We keep the database off the hot path by aggregating writes in sharded Redis counters and folding them into the database in batches, accepting eventual consistency to get the throughput.

---

## Night before summary

- The database is not on the write path.
- Redis aggregates, the database persists.
- The key is `page_id`, because that is what gets counted.
- A hot page needs the key split into shards.
- `INCR` is already atomic, no locks needed.
- Sync in batches, and make the sync idempotent.
- Eventual consistency is accepted on purpose.

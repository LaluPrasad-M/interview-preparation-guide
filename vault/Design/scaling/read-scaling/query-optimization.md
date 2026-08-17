# Query Optimization and Observability

> [!tldr]
> Read heavy systems then face expensive queries, inefficient joins, poor execution plans and query amplification, which drive evolution toward denormalisation, CQRS, materialized views and deep observability.

Part of [[read-scaling]].

---

## Stage 8: the queries themselves are expensive

Now the infrastructure is stable, Redis healthy, replicas healthy, retries controlled, concurrency manageable. But product complexity grows.

Initially the profile query was `SELECT * FROM profiles WHERE id = ?`. Then the product team adds follower counts, mutual friends, recommendations, activity feed, trending score, badges, analytics, personalisation, and the query becomes something ugly:

```sql
SELECT ...
FROM profiles p
JOIN followers f
JOIN activities a
JOIN recommendations r
JOIN badges b
...
```

The problem is no longer "too many requests". It is "each request is computationally expensive".

**Why this happens naturally.** Normalised databases are wonderful at small scale: clean schema, reduced duplication, strong consistency, easier updates. But normalisation assumes joins are affordable, and at massive read scale joins become expensive because the DB must scan multiple indexes, plan the join, allocate join memory, fetch rows from multiple tables, sort or hash, manage temporary memory and coordinate execution. Under huge traffic those costs multiply enormously.

---

## Stage 9: denormalisation

Instead of a normalised relational truth, you create read optimised data models.

Instead of joining `profiles`, `followers`, `badges` and `activity` on every request, store:

```json
{
 "userId": 123,
 "name": "Rahul",
 "followersCount": 50000,
 "badges": [],
 "recentActivities": []
}
```

directly in one document, cache or read table. Reads become dramatically faster because the expensive joins disappear. This is extremely common in feeds, recommendations, dashboards, analytics, search and notifications.

**The new problem.** Duplicated data exists everywhere. When a user changes their profile picture, updates are required in the profile table, feed cache, recommendation cache, activity cache and denormalised projections. Denormalisation trades write simplicity for read performance.

---

## Stage 10: read and write need different models

Engineers realise something fundamental: the best write schema is often not the best read schema.

Writes want normalisation, transactional consistency and correctness. Reads want denormalisation, aggregation, fast retrieval and optimised query models. Those goals conflict, so the system evolves into `Write Model != Read Model`, which is CQRS.

```text
Writes -> Primary DB

Async pipelines -> Read projections
                -> Search indexes
                -> Cached views
                -> Aggregated tables
```

Reads no longer directly depend on the normalised transactional schema.

**What CQRS costs.** Synchronisation pipelines, projection lag, eventual consistency, replay complexity, projection rebuilding, debugging difficulty. CQRS is powerful but operationally expensive, and it solves a very specific scaling pain rather than being free sophistication.

---

## Stage 11: materialized views

Dashboards need aggregates, counts, rankings and analytics. Running huge aggregation queries repeatedly becomes expensive: `COUNT(*)`, `GROUP BY` and `ORDER BY` across billions of rows burn CPU recomputing the same results.

A materialized view precomputes and stores the result instead of computing the query every time.

The recurring theme again: spend more work ahead of time to make reads cheaper later.

**The tradeoff.** Refresh timing matters, stale data is possible, refresh operations are expensive, incremental refresh is difficult, and synchronisation complexity increases.

---

## Stage 12: pagination becomes the bottleneck

Initially `LIMIT 20 OFFSET 100000` looked harmless. At huge scale it becomes terrible, because the DB still scans and skips huge numbers of rows internally.

Deep pagination itself is expensive, which introduces cursor pagination, seek pagination and continuation tokens.

Instead of `OFFSET 100000`, the system uses `WHERE id > last_seen_id`, which aligns much better with indexes.

---

## Stage 13: covering indexes

Add the required columns to the index so the row fetch is not required.

Queries are still slow because the DB traverses the index and then fetches heap rows, and at massive scale heap fetches become expensive. Can the query be answered entirely from the index itself?

With a covering index the index contains all required columns, so the heap lookup disappears. That reduces memory access, random I/O and heap traversal cost. The cost is larger indexes, slower writes and more memory usage.

The planner recognises that all referenced columns are available in the index, and chooses an index only scan instead of an index scan plus heap fetch.

> [!warning] The PostgreSQL MVCC catch
> PostgreSQL stores transaction visibility in the heap row. To know whether a row is visible to your transaction, the engine may still need heap access, even if the index contains all the columns. A true index only scan requires both the required columns in the index and visibility certainty.

---

## Stage 14: the query planner

**The core mental model.** SQL is declarative. When you write `SELECT * FROM users WHERE id = 10` you are not telling the database how to execute the query, only what result you want. The database decides the scan strategy, join order, join algorithm, sorting strategy, memory allocation and parallelism. That decision making system is the query optimizer.

**The most important insight.** Performance depends more on the execution plan than on the SQL syntax. The same query can run in milliseconds or minutes depending on the chosen plan.

**Why the optimizer exists.** A database may have billions of rows, multiple indexes, many joins and skewed data distributions. There are many possible execution strategies, and the optimizer tries to choose the lowest estimated cost plan using cost based optimisation.

**The production insight.** Optimizer decisions are estimation driven, not perfectly informed. Wrong assumptions lead to a wrong plan, which leads to catastrophic performance.

What the optimizer decides: sequential scan against index scan, join order, nested loop against hash join, sorting strategy, memory allocation, parallel execution.

`EXPLAIN ANALYZE` is the primary production debugging tool for SQL performance. It shows the chosen plan, estimated rows, actual rows, execution timing, scan types, join methods and memory usage.

---

## Stage 15: sequential scan against index scan

**The biggest mental shift.** The wrong model is "index equals always fast". The correct model is "an index is useful only if it reduces total execution cost enough".

**Why the DB ignores indexes.** Suppose `WHERE country = 'India'` matches 70 percent of rows. Using the index means traversing the index, fetching massive row pointers, and performing huge random heap fetches. A sequential scan may actually be cheaper.

**Why sequential scans can be faster.** They benefit from contiguous memory access, cache locality, prefetching and efficient disk page traversal. Index scans often create random I/O, which is expensive.

**Selectivity** means how small the matching subset is. `WHERE email = 'abc@gmail.com'` is high selectivity; `WHERE gender = 'male'` is low. Indexes help mostly when the matching subset is small.

**Bitmap index scan** is used when multiple conditions exist, many rows match, and the optimizer wants to reduce random heap fetches. The DB scans indexes, builds a bitmap, and groups heap access efficiently, balancing index precision against sequential access efficiency.

---

## Stage 16: cardinality estimation failures

**Cardinality estimation** means the optimizer estimating how many rows will match. It is foundational, because the execution strategy depends on the expected row count.

If the optimizer estimates 10 rows and reality is 10 million, it may choose nested loops, index scans and tiny memory, when reality requires hash joins, sequential scans and huge memory. A wrong estimate destroys the entire plan.

**How the DB estimates.** Histograms, value distributions, distinct counts, null fractions and correlation statistics.

**The stale statistics problem.** Initially 1 percent of rows are `PENDING`; later 80 percent are. If statistics are stale, the optimizer still assumes high selectivity and chooses a terrible plan. This is one of the biggest real world DB performance problems.

**The production insight.** The same query can suddenly become slow because the table grew, the distribution changed, statistics went stale, and the optimizer's assumptions became invalid. No code change required.

**Plan instability.** The optimizer may alternate between sequential scan and index scan, causing unstable latency and unpredictable performance. This is called plan flapping.

The huge `EXPLAIN ANALYZE` warning sign is estimated rows of 10 against actual rows of 10 million, which usually indicates a cardinality estimation failure.

---

## Stage 17: join strategy problems

**The mental shift.** Joins are not merely logical relationships. They are physical execution strategies with major CPU, memory, disk and latency implications.

**Nested loop join.** For each outer row, scan or probe the inner table. Good for small datasets, indexed lookups and highly selective queries. Terrible for huge datasets and bad cardinality estimates.

**Hash join.** The DB builds a hash table and probes it efficiently. Excellent for large equality joins on large datasets. The danger is the hash table spilling to disk, which causes temp files and huge latency spikes.

**Merge join.** Efficient when both datasets are sorted and indexes align. Expensive if sorting spills to disk.

**Join order matters enormously.** `A JOIN B JOIN C JOIN D` in different orders gives different intermediate result sizes and massive performance differences. Bad cardinality estimates lead to a bad join order, which leads to catastrophic execution.

This is why denormalisation appeared earlier: repeated joins under heavy read traffic become expensive because join planning, sorting, hashing, memory allocation and intermediate datasets all cost.

---

## Stage 18: N+1 query amplification

One API request silently creates hundreds or thousands of downstream queries. Very common in ORMs, GraphQL and microservices.

**The classic example.** Fetch 100 users, then for each user fetch their orders. That is 1 query plus 100 queries.

**Why it is dangerous.** Not just the query count, but repeated network trips, repeated parsing, repeated connection usage, repeated execution overhead and repeated memory allocations. Under concurrency, N+1 amplifies connection exhaustion, queue buildup, tail latency and retries.

**The ORM danger.** `user.orders` may silently trigger an extra DB query, and loops accidentally create thousands of hidden queries.

**The GraphQL risk.** Nested resolvers can create massive query explosions. Solutions: batching, dataloaders, aggregation, read projections.

**Distributed N+1.** Microservices can create fanout explosions, where one request becomes dozens or hundreds of service calls, causing latency amplification, retry amplification and cascading failures.

N+1 is usually solved with batching, eager loading, aggregation, bulk APIs and denormalised projections.

---

## Stage 19: observability and production debugging

At scale, systems become too complex for intuition alone. Observability is understanding system behaviour under stress, and it needs metrics, tracing, logs and execution analysis.

**RED method.** Rate, Errors, Duration. Used for service and API monitoring.

**USE method.** Utilisation, Saturation, Errors. Applied to CPU, disks, queues, connection pools and thread pools.

**Tail latency matters most.** Distributed systems usually fail first at p95 and p99, not at the average. Tail latency reveals queue buildup, retries, lock contention, spills and hotspots.

**Distributed tracing** tracks the request flow across services, DBs, caches and queues, helping identify bottlenecks, retries, fanout explosions and latency accumulation.

`EXPLAIN ANALYZE` remains one of the most important DB debugging tools, for execution plans, estimated against actual rows, joins, memory spills and timing.

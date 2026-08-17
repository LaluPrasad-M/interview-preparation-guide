# SQL Study Roadmap

> [!tldr]
> Start with indexing and concurrency. Do not start with sharding.

---

## Tier 1, critical

If you are weak here, SDE2 interviews become shaky.

### 1. Query mastery

Be comfortable writing these without thinking: all join types, `GROUP BY` plus `HAVING`, subqueries both correlated and non correlated, CTEs, `EXISTS` against `IN` and their performance difference, and window functions (`ROW_NUMBER`, `DENSE_RANK`, `SUM() OVER`, partitioning).

Common patterns: second highest salary, top N per group, running total, deduplication, find duplicates, last 24 hours query, join plus aggregation. See [[query-patterns]] and [[window-functions]].

### 2. Indexing, the most important for SDE2

Understand deeply: what a B-tree is, clustered against non clustered index, the composite index ordering rule, index selectivity, covering indexes, when an index is useless because of low cardinality, why too many indexes are bad, and index scan against index seek.

**Debug checklist when a query is slow.** Run `EXPLAIN ANALYZE`. Check for a full table scan. Check for wrong index usage. Check composite index order. Check for a missing index. Check the join strategy, nested loop against hash join.

### 3. Transactions and concurrency

Pure SDE2 territory. Deep understanding of ACID properties. Isolation levels and their anomalies: dirty read, non repeatable read, phantom read. `SELECT ... FOR UPDATE`. Row level against table level locking. Deadlocks and why they happen. Optimistic against pessimistic locking.

Be able to design a seat booking system, a bank transfer, and prevention of double payment.

---

## Tier 2, high value

### 4. Performance and scaling

Offset pagination against cursor pagination, keyset pagination, the N plus 1 query problem, batch queries, connection pooling, query caching.

### 5. Database design

1NF, 2NF, 3NF. When to denormalise. Foreign keys against no foreign keys. The soft delete pattern. Many to many table design. Audit log design. Idempotency using unique constraints.

### 6. Schema migrations

Add a column without downtime. Backfill safely. Avoid a full table lock. Rolling migration. The blue green database deployment idea.

---

## Tier 3, system design integration

### 7. Replication

Primary to replica setup, read replica usage, read after write consistency, replica lag. See [[replication-lag]].

### 8. Sharding

Horizontal against vertical partitioning, choosing a shard key, the hot shard problem, rebalancing shards.

### 9. Distributed transactions

Two phase commit, the Saga pattern, why distributed transactions are risky, the outbox pattern. See [[distributed-transactions]].

### 10. SQL against NoSQL trade offs

When to use a relational DB, when to use MongoDB, embedding against referencing, strong consistency against flexibility.

---

## The priority order

1. Indexing and execution plans
2. Transactions and isolation
3. Window functions
4. Pagination and N plus 1
5. Schema evolution
6. Replication and sharding

# MongoDB Indexing

> [!tldr]
> Verify with `explain`, obey the left prefix rule, and order compound fields by equality, then sort, then range.

---

## Always verify index usage

```js
db.collection.explain("executionStats")
```

Look for `IXSCAN`, not `COLLSCAN`.

---

## Compound indexes follow the left prefix rule

```js
{ userId: 1, status: 1 }
```

Efficient for a query on `{ userId: 123 }`, and for `{ userId: 123, status: "ACTIVE" }`.

Not efficient for `{ status: "ACTIVE" }` alone, because the query does not start at the left of the index.

---

## The ESR rule

Equality, then sort, then range. This is how you decide compound index field order.

**Equality fields first.** Exact matches narrow the search space most efficiently.

**Sort fields next.** This avoids an expensive in memory sort.

**Range fields last.** A range scan reduces the effectiveness of every field after it.

### The worked example

```sql
SELECT *
FROM orders
WHERE user_id = 1
  AND status = 'SUCCESS'
  AND amount > 1000
ORDER BY created_at DESC;
```

The good index is `(user_id, status, created_at, amount)`, because `user_id` and `status` are equality, `created_at` is the sort, and `amount` is the range.

**The rules.** Equality first. Sort before range. High selectivity columns are better index candidates. Avoid over indexing, because writes become slower. Use `explain()` or `EXPLAIN ANALYZE` to verify the plan.

**In MongoDB** compound index order is very important, with strong leftmost prefix behaviour. After a range scan using `$gt` or `$lt`, later fields become less useful.

**In SQL** composite indexes follow ESR conceptually too. The query planner is more flexible, but the leftmost prefix rule still matters.

> [!tip] The golden line
> Equality narrows the dataset, sorting avoids an expensive memory sort, and range scans are placed last because they reduce the usefulness of subsequent index fields.

---

## Multikey index

Array fields can be indexed.

```js
{ skills: ["Node", "Kafka", "Redis"] }
```

Mongo indexes each array element separately.

---

## Covered query, the best case

The index contains everything the query needs, so no document lookup is required.

Verify it with `totalDocsExamined = 0`.

---

## TTL index

Automatic deletion using `expireAfterSeconds`. Useful for OTPs, sessions and temporary tokens.

---

## Sparse index

Indexes only the documents that contain the field. Useful when a field exists in a small percentage of documents, giving a smaller index and less memory use.

---

## Text index

Supports simple text search, which is good for search bars and keyword search. It is not a replacement for Elasticsearch or OpenSearch. See [[choosing-a-datastore]].

---

## Aggregation optimisation

Push `$match` as early as possible, to reduce the dataset before `$lookup`, `$sort` and `$group`. See [[aggregation]].

---

## Shard keys

**A good shard key** has high cardinality, even distribution and no hotspots. Examples are `userId` and `tenantId`.

**Avoid** a timestamp, because it is monotonic.

**A bad shard key causes** hot shards, uneven traffic and poor scaling. See [[sharding]].

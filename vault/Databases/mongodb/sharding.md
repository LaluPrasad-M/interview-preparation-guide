# MongoDB Sharding

> [!tldr]
> Sharding only works if most queries include the shard key. Otherwise every query becomes a scatter gather across every shard.

---

## What sharding is

Sharding is splitting one large collection into smaller pieces and storing those pieces on different machines. Each machine stores only part of the data and handles only part of the traffic. MongoDB does this automatically based on the shard key.

---

## With and without sharding

| Aspect | Without sharding | With sharding |
| --- | --- | --- |
| Storage | one machine | spread across many |
| Writes | bottleneck | parallel |
| Reads | heavy scans | targeted |
| Scalability | vertical only | horizontal |
| Failure | the whole system | partial |
| Peak traffic | the DB chokes | the DB survives |

---

## Good shard key properties

High cardinality. Even distribution. Appears in the query filter. Immutable.

**Avoid** low cardinality fields such as `status` or `isActive`, and monotonic values such as `createdAt` or `_id`.

```js
// orders
{ userId: "hashed" }
```

This works because there are millions of users (high cardinality), hashing gives even distribution, and queries match the shard key. Reads and writes then scale linearly with no hotspots at dinner time.

### A worked set of shard keys

| Collection | Shard key | Why |
| --- | --- | --- |
| `orders` | `{ orderId: hashed }` | uniform distribution |
| `restaurants` | `{ location }` | geo queries |
| `users` | `{ userId: hashed }` | even load |

Avoid monotonic keys such as timestamps, and avoid `restaurantId` as the shard key for orders because of hot shard risk.

---

## When the shard key is wrong

If a query does not contain the shard key, the router sends it to all shards and each shard processes it. The results are merged, sorted and returned. That is a scatter gather query, and it kills scalability.

> [!warning] It is worse than a full table scan
> It becomes a parallel full scan across all shards, which adds network overhead, multiplied CPU, and merge cost on top.

> [!tip] The interview ready line
> If the shard key does not align with dominant query patterns, the system performs scatter gather queries, defeating the purpose of horizontal scaling.

---

## Hot shards

If you shard by city and Delhi has 80 percent of traffic, the Delhi shard is overloaded while the others are underutilised. That is a hotspot, and it happens because the shard key distribution is skewed.

**How to fix it.** Use a composite shard key, for example `(city, restaurant_id)`. Use a hashed shard key. Split the hot partition further. Use regional clusters.

---

## The sharding decision affects schema design

Ask: is the dataset bigger than a single machine? Is traffic uneven? Is there hotspot risk?

And never jump to sharding first. See the [[study-roadmap]] scaling hierarchy: query optimisation, indexing, caching, read replicas, partitioning, then sharding.

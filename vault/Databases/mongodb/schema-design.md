# MongoDB Schema Design

> [!tldr]
> In MongoDB, schema follows queries, not normalisation. Start with access patterns, never with entities.

---

## Start with access patterns, not entities

This is the number one MongoDB rule.

Ask: what queries happen most? What is read together? What grows unbounded? What is write heavy?

For a food delivery system: get restaurant plus menu is frequent, order history by user is frequent, status updates are frequent writes.

**Beginner approach.** "We will have users, restaurants, orders, menus, feedback."

**SDE2 approach.** "Before designing collections, I want to understand queries, scale, and access patterns, because MongoDB schema follows queries, not normalisation."

### The questions to ask first

Read or write heavy? Peak traffic, for example lunch and dinner spikes? Strong or eventual consistency? Order lifecycle complexity? Geo based discovery? Analytics against transactional workload?

> [!tip] Key principle
> In MongoDB, design for reads first, then writes, then storage.

---

## Aggregate roots

An aggregate root is a boundary within which data must be strongly consistent and updated atomically. In MongoDB terms, one aggregate root is roughly one main document.

Everything inside it changes together, is read together, and is updated atomically.

MongoDB guarantees atomicity at the document level and fast single document reads and writes, so it pushes you to ask: what data must always stay consistent together? That group becomes an aggregate.

**Aggregate is not collection.** An aggregate is a logical boundary, a design concept. A collection is physical storage. Usually one aggregate root maps to one collection, but not always.

### The rules

1. All updates inside an aggregate must be atomic.
2. Aggregates reference each other by ID only.
3. Never update two aggregates in one transaction unless it is unavoidable.

---

## The SQL mental model comparison

| Aspect | SQL | MongoDB |
| --- | --- | --- |
| Primary design unit | table | document |
| Atomicity scope | transaction | document |
| Normalisation | default | optional |
| Joins | core | avoided |
| Consistency | cross table | per aggregate |

---

## Embedding against referencing

> [!tip] The golden rule, an interview favourite
> Embed when data is read together and updated together. Reference when data changes independently and grows unbounded.

**Embed if all are true.** A one to few relationship. Read together 90 percent of the time. Bounded size. Rare updates. The child does not outlive the parent.

**Reference if any are true.** One to many and unbounded. High write frequency. Independent lifecycle. Shared across parents. Risk of hitting the 16 MB limit.

| Situation | Choice |
| --- | --- |
| One to few | embed |
| High read together | embed |
| Independent lifecycle | reference |
| Large or growing | reference |
| Write heavy child | reference |

Embed for read performance. Reference for write scalability.

### When referencing is the right choice

| Situation | Why |
| --- | --- |
| Large documents | avoid the 16 MB limit |
| Shared entities | avoid duplication |
| Independent lifecycle | it changes separately |
| Write heavy shared data | avoid fan out updates |
| Analytics collections | normalise for queries |

---

## What referencing actually means

Instead of storing the full related object inside a document, you store only the ID of another document and fetch it separately when needed.

This is similar to foreign keys in SQL, but with no enforced joins and no automatic integrity. The database does not enforce relationships, and the application code is responsible for joining data. That is a deliberate design choice to enable horizontal scaling.

MongoDB will not validate the reference, auto fetch related data, or prevent dangling references. That responsibility is yours.

**Why MongoDB allows this.** It optimises for distributed systems, independent scaling of collections, and flexible schemas. Embedding everything would cause document bloat, increase write amplification, and make sharding painful. Referencing keeps documents small, stable and shard friendly.

---

## Worked example 1: user and orders

One user, many orders, and orders grow unbounded over time. This is not a good embedding case.

```js
// users collection
{
  _id: ObjectId("u1"),
  name: "Rahul",
  email: "rahul@gmail.com"
}

// orders collection
{
  _id: ObjectId("o1"),
  userId: ObjectId("u1"),   // reference
  amount: 1200,
  status: "PLACED",
  createdAt: ISODate("2025-01-10")
}
```

**Why embedding would break in production.** The user document grows unbounded, the 16 MB document size limit gets hit, every order write updates the user document, and a hot user creates write contention.

**How referencing saves production.** Orders can scale to billions, the user document stays small, orders can be sharded independently, and write throughput stays stable.

---

## Worked example 2: product and category

Products belong to categories. Categories are small and stable, products are many.

```js
// categories
{
  _id: ObjectId("c1"),
  name: "Electronics"
}

// products
{
  _id: ObjectId("p1"),
  name: "iPhone",
  price: 80000,
  categoryId: ObjectId("c1")   // reference
}
```

Category data is reused by many products, and updating a category name should reflect everywhere.

**The problem avoided.** If embedded, updating the category name means updating millions of products, which is massive write amplification and a risky bulk update. With a reference you update the category once.

---

## Worked example 3: blog post and author, hybrid thinking

```js
// authors
{
  _id: ObjectId("a1"),
  name: "Rahul",
  bio: "Backend Engineer"
}

// posts
{
  _id: ObjectId("p1"),
  title: "MongoDB Design",
  authorId: ObjectId("a1")   // reference
}
```

The SDE2 level insight is that you might also embed a snapshot:

```js
authorSnapshot: {
  name: "Rahul"
}
```

This avoids fetching the author on every read while keeping the canonical data separate. It is called controlled denormalisation.

---

## Fetching referenced data

**Option 1, multiple queries, the most common.**

```js
const order = await Order.findById(orderId);
const user = await User.findById(order.userId);
```

Simple, cacheable and flexible. The trade off is two network calls.

**Option 2, aggregation with `$lookup`, MongoDB's join.**

```js
db.orders.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "userId",
      foreignField: "_id",
      as: "user"
    }
  }
])
```

> [!warning] SDE2 caution
> `$lookup` can be expensive. Avoid it on hot paths at scale. It is fine for admin or analytics queries.

**With Mongoose.**

```js
const UserSchema = new mongoose.Schema({
  name: String,
  email: String
});

const OrderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  amount: Number,
  status: String
});

const order = await Order
  .findById(orderId)
  .populate("userId");
```

This is application level joining, not DB enforced. `populate` is easy to use and dangerous at scale if overused, because it causes N plus 1 query issues. Avoid deep populates on hot paths.

---

## What breaks in production with referencing

**1. Dangling references.** A user is deleted but orders still exist, and MongoDB will not stop this. Mitigate with soft deletes, background cleanup jobs and application level checks.

**2. The N plus 1 query problem.** Fetching 100 orders triggers 100 user queries. Mitigate with batch fetching, caching, and careful aggregation pipelines.

**3. Cross shard joins.** If collections are sharded differently, `$lookup` becomes expensive and performance degrades badly. Mitigate by aligning shard keys, or avoiding joins on hot paths.

---

## Denormalisation

Denormalisation in MongoDB is the intentional duplication of data to optimise read performance and preserve atomicity. It is not only copying raw fields, it also includes storing derived or aggregated data.

The key word is intentional. It is not accidental redundancy, it is a design choice.

MongoDB encourages it because MongoDB is optimised for fast reads, single document atomic operations and high scale. Reads usually need complete objects, joins are expensive, and document reads are cheap.

**Denormalisation check.** Can I duplicate small data to avoid `$lookup`? Can I store aggregates such as `avgRating`, `orderCount` or `lastOrderStatus`? Is eventual consistency acceptable?

MongoDB prefers duplication over joins.

---

## Index strategy, mandatory

Every query backed by an index. Compound indexes follow filter, then sort, then projection. Avoid over indexing write heavy collections. Use partial indexes where possible.

```js
{ userId: 1, createdAt: -1 }
```

---

## Document size and growth

Any unbounded arrays? Any frequent `$push`? Any risk of hot documents?

> [!warning] Growing arrays plus sharding is a disaster.

---

## Order lifecycle complexity, a worked case

**Simple lifecycle, low complexity.** `PLACED -> CONFIRMED -> DELIVERED`. Few states, single owner, minimal race conditions. Design: a single orders document with an embedded status field and atomic updates.

**Real food delivery lifecycle, high complexity.**

```text
PLACED
-> PAYMENT_PENDING
-> PAYMENT_SUCCESS
-> RESTAURANT_ACCEPTED
-> PREPARING
-> READY_FOR_PICKUP
-> PICKED_UP
-> ON_THE_WAY
-> DELIVERED
-> COMPLETED / CANCELLED / REFUNDED
```

Who updates what: the user cancels, the payment service owns payment state, the restaurant owns preparation, the delivery partner owns pickup and delivery.

This is hard because of concurrent updates, partial failures, required idempotency, and the need for an audit trail.

| Concern | Design choice |
| --- | --- |
| Multiple updates | a single orders document |
| State history | embedded `statusTimeline[]` |
| Atomicity | transactions or `$set` |
| Debugging | an event log inside the order |

```json
{
  "_id": "order123",
  "status": "ON_THE_WAY",
  "statusTimeline": [
    { "state": "PLACED", "at": "10:01" },
    { "state": "PREPARING", "at": "10:10" },
    { "state": "ON_THE_WAY", "at": "10:35" }
  ]
}
```

> [!tip] Say this
> Order lifecycle is complex and state driven, so I would keep the entire lifecycle in a single order document to ensure atomic updates, strong consistency, and easy state validation.

---

## The design checklist

Before you say done: queries identified, embed against reference justified, document size safe, indexes defined, sharding discussed, failure cases considered.

> [!tip] The closing one liner
> My MongoDB designs are query driven, embed for performance, reference for scale, and shard for growth.

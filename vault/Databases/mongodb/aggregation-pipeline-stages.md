# Aggregation Pipeline Stages

> [!tldr]
> Advanced pipeline operators: sorting, joining, unwinding, grouping, and computed results.

Part of [[aggregation]].

---

## `$sort` and `$limit`

```js
db.orders.aggregate([
   { $sort: { amount: -1 } }
])

db.users.aggregate([
   { $limit: 5 }
])
```

---

## `$lookup`, the equivalent of a left outer join

```js
db.orders.aggregate([
   {
      $lookup: {
         from: 'users',
         localField: 'userId',
         foreignField: '_id',
         as: 'user'
      }
   }
])
```

---

## `$unwind`, flattening arrays

```js
db.posts.aggregate([
   { $unwind: '$tags' }
])
```

Combined with `$lookup` to turn the joined array into a single object:

```js
db.orders.aggregate([
   {
      $lookup: {
         from: 'users',
         localField: 'userId',
         foreignField: '_id',
         as: 'user'
      }
   },
   { $unwind: '$user' }
])
```

---

## Worked pipelines

**Top selling products.**

```js
db.orders.aggregate([
   {
      $group: {
         _id: '$productId',
         totalSold: { $sum: '$quantity' }
      }
   },
   { $sort: { totalSold: -1 } },
   { $limit: 5 }
])
```

**Tag frequency.**

```js
db.posts.aggregate([
   { $unwind: '$tags' },
   {
      $group: {
         _id: '$tags',
         count: { $sum: 1 }
      }
   }
])
```

**Filtering after grouping, revenue above 1000.**

```js
db.orders.aggregate([
   {
      $group: {
         _id: '$userId',
         totalRevenue: { $sum: '$amount' }
      }
   },
   {
      $match: {
         totalRevenue: { $gt: 1000 }
      }
   }
])
```

---

## `$facet`, running pipelines in parallel

The standard use is pagination plus a total count in one round trip.

```js
db.posts.aggregate([
   {
      $facet: {
         data: [
            { $skip: 0 },
            { $limit: 10 }
         ],
         total: [
            { $count: 'count' }
         ]
      }
   }
])
```

---

## `$count`, `$addFields`, `$push`, `$first`

```js
db.users.aggregate([
   { $count: 'totalUsers' }
])
```

```js
db.orders.aggregate([
   {
      $addFields: {
         tax: { $multiply: ['$amount', 0.18] }
      }
   }
])
```

```js
// Collect grouped values into an array
db.orders.aggregate([
   {
      $group: {
         _id: '$userId',
         orders: { $push: '$amount' }
      }
   }
])
```

```js
// First order date per user
db.orders.aggregate([
   { $sort: { createdAt: 1 } },
   {
      $group: {
         _id: '$userId',
         firstOrder: { $first: '$createdAt' }
      }
   }
])
```

---

## The compound index for a sorted filter

```js
find({
   status: 'SUCCESS',
   createdAt: { $gt: someDate }
})
.sort({ createdAt: -1 })
```

The best index is `{ status: 1, createdAt: -1 }`. See [[indexing]] for the ESR rule behind that.

---

## The operator reference

| Aggregation operator | Meaning |
| --- | --- |
| `$sum` | total |
| `$avg` | average |
| `$min` | minimum |
| `$max` | maximum |
| `$push` | push into an array |
| `$first` | first value |
| `$last` | last value |
| `$count` | count documents |

| Query operator | Meaning |
| --- | --- |
| `$gt` | greater than |
| `$lt` | less than |
| `$gte` | greater or equal |
| `$lte` | less or equal |
| `$in` | value exists in the array |
| `$or` | OR condition |
| `$and` | AND condition |
| `$exists` | field existence |

---

## The golden rules

| Rule | Why |
| --- | --- |
| `$match` early | reduces the dataset |
| Avoid a large `$skip` | performance |
| Use cursor pagination | scalable |
| Index the filter fields | avoids collection scans |
| Index the sort fields | avoids an in memory sort |
| `$lookup` is expensive | use it carefully |
| Aggregation is stage chaining | the core mental model |

---

## The shape to memorise

Most interview aggregations are this.

```js
db.collection.aggregate([
   { $match: {} },
   {
      $group: {
         _id: '$field',
         total: { $sum: '$amount' }
      }
   },
   { $sort: { total: -1 } },
   { $limit: 5 },
   { $project: {} }
])
```

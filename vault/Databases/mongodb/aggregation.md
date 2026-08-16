# MongoDB Queries and Aggregation

> [!tldr]
> Aggregation is stage chaining. Memorise the shape: match, group, sort, limit, project.

---

## Basic find queries

```js
db.users.find({})

db.users.find({ name: 'Rahul' })

db.users.find({ age: { $gt: 18 } })

db.users.find({ age: { $lt: 30 } })

// AND, by listing both conditions
db.users.find({ age: { $gt: 18 }, city: 'Chennai' })

// OR
db.users.find({
   $or: [
      { city: 'Chennai' },
      { city: 'Delhi' }
   ]
})

// IN
db.users.find({ city: { $in: ['Chennai', 'Delhi'] } })

// Field existence
db.users.find({ email: { $exists: true } })

// Regex, case insensitive
db.users.find({ name: /rah/i })
```

---

## Sorting and pagination

```js
db.users.find().sort({ age: 1 })       // ascending
db.users.find().sort({ createdAt: -1 }) // descending

db.users.find().limit(10)
db.users.find().skip(20).limit(10)
```

Cursor pagination, which is the one that matters at scale:

```js
db.posts.find({
   _id: { $gt: lastSeenId }
})
.limit(20)
```

See [[api-design]] for why cursors beat offsets.

---

## The aggregation shape

```js
db.collection.aggregate([
   { stage1 },
   { stage2 },
   { stage3 }
])
```

---

## `$match`, the equivalent of `WHERE`

```js
db.orders.aggregate([
   { $match: { status: 'SUCCESS' } }
])

db.users.aggregate([
   { $match: { age: { $gt: 18 } } }
])
```

---

## `$group`, the equivalent of `GROUP BY`

```js
// Count users per city
db.users.aggregate([
   {
      $group: {
         _id: '$city',
         count: { $sum: 1 }
      }
   }
])

// Total revenue per user
db.orders.aggregate([
   {
      $group: {
         _id: '$userId',
         totalRevenue: { $sum: '$amount' }
      }
   }
])

// Average, max and min follow the same shape
db.employees.aggregate([
   {
      $group: {
         _id: '$department',
         avgSalary: { $avg: '$salary' },
         maxSalary: { $max: '$salary' },
         minSalary: { $min: '$salary' }
      }
   }
])
```

---

## `$project`, the equivalent of `SELECT`

```js
// Include fields
db.users.aggregate([
   { $project: { name: 1, age: 1 } }
])

// Exclude _id
db.users.aggregate([
   { $project: { name: 1, _id: 0 } }
])

// A computed field
db.users.aggregate([
   {
      $project: {
         fullName: {
            $concat: ['$firstName', ' ', '$lastName']
         }
      }
   }
])
```

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

---

## Cursor streaming for large result sets

Loading 10 million documents into memory kills the process.

```js
await Transaction.find({ bankId: "S23" }) // loads everything, bad
```

Use a cursor instead.

```js
const mongoose = require('mongoose')

async function processLargeDataset() {
  await mongoose.connect('mongodb://localhost:27017/test')

  const Transaction = mongoose.model('Transaction', new mongoose.Schema({
    userId: String,
    amount: Number,
    bankId: String,
    status: String,
    createdAt: Date
  }))

  // A cursor instead of loading everything
  const cursor = Transaction.find({ bankId: "S23" }).cursor()

  let totalAmount = 0
  let count = 0

  for await (const doc of cursor) {
    totalAmount += doc.amount
    count++
  }

  console.log(`Processed ${count} transactions`)
  console.log(`Total amount: ${totalAmount}`)
}

processLargeDataset()
```

`.cursor()` turns the query into a stream. MongoDB fetches results in batches, memory stays stable, and you process one document at a time.

**When to use it.** Exporting large data, data migration, ETL jobs, bulk analytics, background batch jobs.

---

## Change streams for real time reaction

Watching for a status becoming `FAILED` so you can alert.

```js
const mongoose = require('mongoose')

async function watchTransactionFailures() {
  await mongoose.connect('mongodb://localhost:27017/test')

  const Transaction = mongoose.model('Transaction')

  const changeStream = Transaction.watch([
    {
      $match: {
        operationType: "update",
        "updateDescription.updatedFields.status": "FAILED"
      }
    }
  ])

  changeStream.on('change', (change) => {
    console.log("Transaction failure detected:")
    console.log(change.documentKey._id)
  })
}

watchTransactionFailures()
```

MongoDB watches the oplog, matches only updates, and triggers only when the status becomes `FAILED`.

> [!warning] Requires a replica set
> Change streams need a replica set, even a single node one. They do not work on a standalone server.

**When to use them.** Real time notifications, live dashboards, event driven microservices, auditing, syncing services. This is the MongoDB equivalent of [[change-data-capture]].

---

## Read stream against change stream

| Feature | Cursor stream | Change stream |
| --- | --- | --- |
| Purpose | process existing data | react to new changes |
| Trigger | a manual query | database updates |
| Direction | pulls a finite result set | pushes an unbounded event feed |
| Ends | when the result set is exhausted | never, until you close it |

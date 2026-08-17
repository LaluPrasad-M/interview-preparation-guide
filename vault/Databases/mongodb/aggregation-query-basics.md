# Basic Find Queries and Sorting

> [!tldr]
> MongoDB queries use find() with operators, and cursor pagination for large result sets.

Part of [[aggregation]].

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

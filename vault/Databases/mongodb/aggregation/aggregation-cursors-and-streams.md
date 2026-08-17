# Cursors and Change Streams

> [!tldr]
> Cursor streaming processes large datasets without loading everything into memory; change streams watch for real-time database changes.

Part of [[aggregation]].

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

# Consistency, Atomicity and Transactions in MongoDB

> [!tldr]
> MongoDB guarantees atomicity at the document level. Model so that critical updates fit in one document, and reach for transactions only when cross document consistency is unavoidable.

---

## Single document atomicity, the default guarantee

An operation is atomic if it is applied completely or not at all. MongoDB guarantees this at the document level, so multiple fields in one document updated in one operation are always consistent.

```js
db.users.updateOne(
  { _id: 1 },
  {
    $set: { balance: 900 },
    $inc: { rewardPoints: 10 }
  }
)
```

Either both updates happen or neither happens. No transaction needed.

---

## Multi document transactions

Transactions extend atomicity across multiple documents and collections, so all operations succeed together or all are rolled back.

```js
async function performTransaction(client) {
  const session = client.startSession();

  try {
    session.startTransaction({
      readConcern: { level: 'snapshot' },
      writeConcern: { w: 'majority' },
      readPreference: 'primary'
    });

    const db = client.db('ecommerce');

    // Action A: update inventory
    await db.collection('inventory').updateOne(
      { item: "laptop" },
      { $inc: { qty: -1 } },
      { session }
    );

    // Action B: create the order
    await db.collection('orders').insertOne(
      { userId: "user123", item: "laptop", status: "confirmed" },
      { session }
    );

    await session.commitTransaction();
  } catch (error) {
    await session.abortTransaction();
    console.error("Transaction aborted due to error: ", error);
  } finally {
    await session.endSession();
  }
}
```

### The cost of transactions

| Cost | Why |
| --- | --- |
| Higher latency | two phase commit |
| Reduced throughput | locks held longer |
| More failure cases | retry logic needed |
| Harder scaling | especially across shards |

This is why MongoDB recommends avoiding transactions unless necessary.

---

## When to use which

**Use atomicity when** the data fits in one document, the fields change together, write throughput is high, and simple rollback is not needed.

**Use transactions when** multiple documents must stay consistent: money movement, inventory plus order, legal or compliance flows.

> [!tip] The interviewer's favourite principle
> In MongoDB, I first try to model data so that critical updates fit within a single document and rely on atomic updates. I only use transactions when cross document consistency is unavoidable.

Use them only for payment plus order creation, and inventory reservation. Transactions hurt throughput.

---

## Strongest global consistency

This setup ensures a write is confirmed by the majority and the read is verified to come from the actual primary.

```js
// 1. The write: ensure it is on a majority of nodes
await orders.insertOne(
  { orderId: 501, status: "SUCCESS", amount: 99 },
  { writeConcern: { w: 'majority', j: true, wtimeout: 5000 } }
);

// 2. The read: guaranteeing you see the absolute latest
const latestOrder = await orders.findOne(
  { orderId: 501 },
  { readPreference: 'primary', readConcern: { level: 'linearizable' } }
);
```

A majority read concern is also available on its own:

```js
await accounts.findOne(
  { _id: userId },
  { readConcern: { level: "majority" } }
);
```

**What this means.** `w: "majority"` acknowledges the write only after a majority of replicas persist it. `readConcern: "majority"` reads only committed data replicated to a majority. Together that gives stronger consistency.

---

## Strong against eventual consistency

**Strong consistency.** When a write succeeds, all subsequent reads see the latest data.

MongoDB supports it through primary reads (`readPreference: primary`), majority write concern, and transactions for multi document writes.

Use it for orders, payments, wallet balances and inventory decrements. In food delivery that means order status transitions, payment success or failure, and refunds. You cannot afford stale reads for money or order state.

**Eventual consistency.** Data becomes consistent over time but may be briefly stale.

MongoDB supports it through reads from secondaries, async replication, and denormalised or duplicated data.

Use it when read volume is high, slight staleness is acceptable, and performance matters more than exact accuracy. In food delivery that means restaurant ratings, menu views, delivery ETA and the order history page.

> [!tip] The interview perfect answer
> In a food delivery system, I would use strong consistency for transactional flows like orders and payments, and eventual consistency for read heavy features like restaurant listings, ratings and analytics.

---

## Read preference in practice

| Data | Setting |
| --- | --- |
| Orders and payments | `readPreference: "primary"`, `writeConcern: { w: "majority" }` |
| Restaurant listing and ratings | `readPreference: "secondaryPreferred"` |

# Flash Sale Inventory

> [!tldr]
> The Redis layer here is not a cache. It is an operational concurrency layer, which is why the usual [[ttl|TTL]] and stampede advice does not apply.

---

## The problem

A flash sale system: lightning deals, ticket booking, limited console or sneaker drops.

This means 5 million concurrent users, over 1 million purchase attempts per minute, and extremely hot inventory keys. Correctness requirements are strict, and overselling must never happen.

The hardest part is preventing multiple users from successfully purchasing the same inventory unit simultaneously.

---

## The design principles

| Concern | Solution |
| --- | --- |
| Hot write contention | Redis atomic reservation |
| Database overload | Kafka buffering plus batching |
| Overselling | Lua scripts plus a reservation model |
| Durability | PostgreSQL |
| Massive concurrency | horizontal scaling |
| Retry safety | idempotency keys |
| Flash sale spikes | async architecture |

---

## The architecture

```text
                        +----------------------+
                        |        Client        |
                        +----------+-----------+
                                   |
                     +-------------v-----------+
                     |     API Gateway / LB    |
                     |  Rate limit + auth      |
                     +-------------+-----------+
                                   |
                  +----------------v------------+
                  |    Inventory API Service    |
                  +----------------+------------+
                                   | Atomic reserve
                                   v
                        +----------------------+
                        |        Redis         |
                        | Inventory counters   |
                        | Reservation store    |
                        +----------+-----------+
                                   | Produce event
                                   v
                        +----------------------+
                        |        Kafka         |
                        | inventory-events     |
                        +----------+-----------+
                                   |
             +---------------------+------------------+
             |                     |                  |
             v                     v                  v
 +------------------+   +------------------+  +------------------+
 | Reservation      |   | Payment          |  | Notification     |
 | Consumer         |   | Consumer         |  | Consumer         |
 +--------+---------+   +--------+---------+  +------------------+
          |                      |
          v                      v
 +------------------+   +------------------+
 | Batch Flush      |   | Payment Gateway  |
 | Worker           |   | Integration      |
 +--------+---------+   +------------------+
          |
          v
 +-----------------------------+
 | PostgreSQL Primary          |
 | inventory + orders          |
 +--------------+--------------+
                |
                v
 +-----------------------------+
 | PostgreSQL Read Replicas    |
 +-----------------------------+
```

---

## Step 1 and 2: the reservation

The API service does not touch PostgreSQL directly, because Postgres cannot handle a million concurrent updates to the same inventory row. Redis acts as a concurrency shock absorber.

```text
inventory:ps5 = 100
```

```lua
local stock = tonumber(redis.call("GET", KEYS[1]))

if stock > 0 then
    redis.call("DECR", KEYS[1])
    return 1
else
    return 0
end
```

> [!warning] Why the Lua script is mandatory
> Without it you would do `GET`, then check, then `DECR` as three round trips. Two users can both read a stock of 1 and both succeed. Lua makes the check and decrement atomic inside Redis's single threaded loop.

---

## Step 3: the Kafka event

```json
{
  "eventId": "evt-123",
  "reservationId": "res-456",
  "productId": "ps5",
  "userId": "user-1",
  "timestamp": 1710000000
}
```

Kafka gives durable buffering for spikes, async decoupling to protect the database, replay for retries, a persistent log across crashes, and partitioned consumption for horizontal scale.

**Topic design.** `inventory-events` with 64 partitions, keyed by `productId`.

Partitioning by product matters because ordering matters for a single product's inventory. All events for one product land on one partition, which preserves order. See [[partitioning]].

---

## Step 4: the consumers

```js
while (true) {
   const events = kafkaConsumer.poll(100)

   for (const event of events) {
      processReservation(event)
   }
}
```

Consumers validate the reservation, perform idempotency checks, orchestrate persistence, aggregate writes and trigger the payment workflow.

### Idempotency is critical

If Kafka retries a message, the same reservation could be processed twice.

```sql
CREATE TABLE processed_events (
    event_id VARCHAR PRIMARY KEY,
    processed_at TIMESTAMP
);
```

The consumer checks `SELECT * FROM processed_events WHERE event_id = ?` and ignores duplicates. See [[idempotency]].

---

## Step 5 and 6: aggregation and batch flush

Instead of one database write per purchase, the consumer aggregates.

```text
inventory_delta:ps5 = -12000
```

```js
async function flushInventory(productId) {
   const delta = await redis.get(`inventory_delta:${productId}`)

   if (!delta) return

   await postgres.query(`
      UPDATE inventory
      SET stock = stock + $1
      WHERE product_id = $2
   `, [delta, productId])

   await redis.del(`inventory_delta:${productId}`)
}
```

Flush every 5 seconds, or every 50,000 updates, or on a memory threshold.

**The gain.** A million `UPDATE` statements becomes roughly a hundred batched updates. That is a massive reduction in [[write-ahead-log|WAL]] volume, lock contention and [[fsync]] calls. See [[write-scaling]].

---

## The schema

```sql
CREATE TABLE inventory (
    product_id VARCHAR PRIMARY KEY,
    available_stock INT,
    reserved_stock INT,
    updated_at TIMESTAMP
);

CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    user_id VARCHAR,
    product_id VARCHAR,
    status VARCHAR,
    created_at TIMESTAMP
);
```

---

## Step 7: payment and expiry

A separate consumer group handles payment. On success the order is confirmed. On failure the reservation is released and Redis rolls back with `INCR inventory:ps5`.

**The reservation timeout worker.** If a user reserves but never pays, the reservation expires after, say, 10 minutes and the inventory is restored.

---

## The nuance about cache stampede

> [!warning] This Redis layer is not an ordinary cache
> It is an operational concurrency layer. So TTL based expiry is usually avoided, persistent inventory keys are preferred, and synchronisation is event driven rather than lazy.

That is why the advice in [[caching-problems]] about randomised TTLs does not transfer here. Expiring an inventory key would lose the truth, not just a cached copy.

---

## The five Redis failure modes

**1. [[hot-key|Hot key]].** `inventory:ps5` takes millions of requests. Mitigate with Redis Cluster and sharding keys across nodes. See [[redis-cluster]].

**2. Single thread saturation.** The core saturates. Mitigate with clustering, request shedding, local buffering and partitioning.

**3. Replication lag.** A replica shows stale inventory. Send critical writes and read after write traffic to the primary.

**4. Redis crash.** Inventory could be lost. Mitigate with AOF persistence, Kafka replay and database reconciliation.

**5. Duplicate Kafka consumption.** Mitigate with the idempotency table above.

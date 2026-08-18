# Outbox Pattern

> [!tldr]
> The outbox pattern solves the dual write problem by guaranteeing that database writes and event publishes stay consistent through transactional atomicity and a reliable relay.

Part of [[distributed-transactions]].

---

## The outbox problem

Suppose:

```js
await createOrder();
await kafka.publish();
```

What if the DB write succeeds and the Kafka publish fails? Now the order exists and the event is missing. That is a correctness bug and a very common interview scenario.

### Transactional outbox

Instead of writing the order and then publishing the event, write the order and write an outbox event inside the same database transaction.

```sql
BEGIN;

INSERT INTO orders(...);

INSERT INTO outbox_events(...);

COMMIT;
```

Now the order and the event are committed atomically.

### The outbox relay

A background worker continuously reads the outbox table, publishes the Kafka event, and marks the event processed.

Run more than one poller for throughput and a race appears: two pollers query at the same instant and grab the same unprocessed rows, so the same message goes out twice from two different processes at once.

```sql
SELECT *
FROM outbox_events
WHERE processed = false
ORDER BY created_at
LIMIT 100
FOR UPDATE SKIP LOCKED;
```

`FOR UPDATE` locks the rows that a poller just read. `SKIP LOCKED` tells any other poller running the same query to skip those locked rows instead of blocking behind them, so it grabs the next unlocked batch instead. That is what lets you run several pollers side by side without a distributed lock coordinating them.

```text
                    +-- Business Table
Request -> DB Txn --+
                    +-- Outbox Table
                           |
                           v
                       Publisher
                           |
                           v
                         Kafka
```

This guarantees there is no order without an event, which is the entire goal. It is one of the highest frequency senior backend interview topics.

Without an outbox, a DB success plus a Kafka failure creates lost events. With an outbox, the DB success plus the outbox success means the Kafka publish eventually succeeds. A huge difference.

### Two ways to relay the records

**Polling publisher.** A worker periodically queries:

```sql
SELECT *
FROM outbox_events
WHERE status = 'PENDING'
LIMIT 100;
```

It publishes them to Kafka and marks them processed. Simple, and a perfectly valid outbox implementation.

**CDC or change streams.** Instead of polling, a tool like Debezium watches the database transaction log, sees inserts into the outbox table, and publishes them.

```text
Outbox Table
     |
     | DB transaction log
     v
CDC (for example Debezium)
     |
     v
Kafka
```

This gives lower latency and avoids repeated polling, but adds infrastructure and operational complexity.

> [!warning] Keep these two ideas separate
> The outbox pattern solves the dual write problem. CDC or polling solves how you relay the outbox records to the message broker. They are different layers.

For interviews, default to outbox plus polling unless scale or latency justifies CDC. Do not throw Debezium into a moderate scale system merely because you are using an outbox.

> [!warning] Outbox is not exactly once
> The relay can publish an event and crash before marking it processed, causing a duplicate publish. Consumers still need to be idempotent.

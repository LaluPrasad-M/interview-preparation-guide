# Consumer Groups and Offsets

> [!tldr]
> Partitions are physical data. Consumer groups are logical pointers. That one distinction explains most Kafka design mistakes.

---

## The golden rule of consumer groups

Within a single consumer group, a message published to a topic is read by exactly **one** consumer.

Kafka uses consumer groups to load balance work. If 100 payment events come in, 10 servers in a single group process 10 events each.

> [!warning] The silent failure
> If you put 5,000 WebSocket servers into a single consumer group, Kafka maps each partition to only one server. One server broadcasts to its 1,000 users, and 4,999,000 users see nothing.

---

## Achieving broadcast

To have every server read every message, each server must exist in its own unique consumer group, for example `Group-1` through `Group-5000`.

When a producer publishes a message, Kafka routes a copy of that message's partition to every distinct group.

---

## Partitions against consumer groups, the cost divide

**Partitions are the book.** Creating 5,000 partitions means creating thousands of physical hard drive directories, replicating them across the cluster, and managing constant [[leader-election|leader elections]] if brokers crash. It is incredibly heavy.

**Consumer groups are the bookmark.** A consumer group is just a tracking name and an integer, the offset. Kafka tracks this in memory and writes tiny updates to an internal topic. It is incredibly cheap.

---

## Offsets

Consumers track their position via offsets. The offset is committed either to Kafka, using the default internal topic `__consumer_offsets`, or to an external store.

Consumers in a group divvy the partitions among themselves, with each partition consumed by only one member, which is what enables horizontal scaling.

---

## Auto commit against manual commit

**Auto commit is the danger zone.** By default, Kafka client libraries set `auto-commit: true`. A background timer tells Kafka "yes, we read these messages" every 5 seconds, regardless of whether your application successfully saved them to the database. If your app pulls 5,000 messages, auto commits, and then crashes before hitting Postgres, those 5,000 messages are permanently lost.

**Manual commit is the enterprise standard.** You set `auto-commit: false`. Your code pulls 5,000 messages and runs the Postgres `INSERT`. Only after Postgres returns success does your code call `consumer.commitOffsets()`.

**When do you commit?** The absolute last line of your processing function. This guarantees at least once delivery. If you crash before committing, Kafka resends the messages when you reboot.

---

## Kafka tracks offsets, not business success

> [!tip] The interview line
> Kafka knows whether an offset was committed. Kafka does not know whether your business operation succeeded.

**At most once.**

```text
Commit Offset
   |
Process Message
```

Risk: message loss.

**At least once.**

```text
Process Message
   |
Commit Offset
```

Risk: duplicate processing. This is the most common production choice.

> [!tip] Say this
> Most production systems prefer duplicates over data loss.

---

## The classic duplicate processing scenario

```text
Process Order
   |
Database Insert Succeeds
   |
Offset Commit Fails
   |
Consumer Restarts
   |
Message Replayed
```

The result is a duplicate order. Kafka is behaving correctly, because the offset was never committed.

---

## Preventing duplicate processing

### 1. The unique data store, deduplication

Maintain a processed IDs table in your database. Every Kafka message should carry a unique business ID such as `transaction_id` or `event_id`.

Before processing, the consumer checks whether the ID exists in the processed table. If it does, the message is ignored. If not, it processes the event and inserts the ID into the table within a single transaction.

### 2. Idempotent writes, upserts

If the consumer's job is simply to update a record, use upsert logic rather than a blind insert. In MongoDB use `findOneAndUpdate` with `upsert: true`. In SQL use `ON CONFLICT DO UPDATE`.

Even if the consumer processes the create order event five times, the database state stays the same because subsequent writes overwrite with identical values.

### 3. Transactional exactly once semantics

If your consumer reads from one Kafka topic and writes to another, the consume transform produce pattern, you can use Kafka transactions. You wrap the offset consumption and the new message production in one atomic transaction. Either both succeed or both fail, which prevents phantom messages between topics.

### 4. Versioning or optimistic locking

This is vital when the order of updates matters or when multiple consumers might touch the same record. Each message includes a version number or timestamp, and the consumer only updates the database if the incoming version is greater than the current version.

If version 5 arrives after version 6 due to a retry, the database rejects version 5 as stale.

---

## The exactly once interview trap

**Bad answer.** Kafka guarantees exactly once.

**Correct answer.** Kafka provides exactly once semantics for Kafka to Kafka transactional workflows using idempotent producers and transactions. Once external systems such as databases, Redis, REST APIs or third party services are involved, application level idempotency is still required.

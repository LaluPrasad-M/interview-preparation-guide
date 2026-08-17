# The Inbox Pattern

> [!tldr]
> Outbox is my service to the world. Inbox is the world to my service. Same dual write problem, opposite direction.

The outbox side is covered in [[distributed-transactions]]. This note is the mirror image and the comparison.

---

## The shared problem

When a service interacts with a database, Kafka and external systems, you face the dual write problem.

```text
1. Update DB
2. Publish Kafka event
```

Either the DB succeeds and Kafka fails, or Kafka succeeds and the DB fails. Both cause inconsistency.

---

## Outbox, in one screen

**Purpose.** Reliable event publishing from your service to external systems.

Instead of updating the DB then publishing, do both inside one transaction.

```text
Business API
  |
DB Transaction
  |-- update business table
  +-- insert outbox_event
  |
COMMIT
  |
Outbox Worker
  |
Publish Kafka
  |
Mark SENT
```

```text
outbox_events
--------------
event_id
aggregate_id
event_type
payload
status
created_at
published_at
retry_count
```

It prevents the case where the DB is committed but the event is lost after a crash, and it gives reliable publishing, replayability, retry safety and eventual consistency.

> [!warning] The limitation
> Outbox does not give globally exactly once delivery. Consumers must still be idempotent.

---

## Inbox

**Purpose.** Reliable event consumption from Kafka, webhooks or external systems.

**The core idea.** Store the incoming event durably before processing it, then process asynchronously.

```text
Kafka/Webhook
  |
Inbox Table Insert
  |
Deduplication
  |
Business Processing
  |
Mark Processed
```

```text
inbox_events
-------------
event_id UNIQUE
source
payload
status
received_at
processed_at
retry_count
```

**Why it exists.** It protects against duplicate delivery, retries, consumer crashes, replay scenarios and out of order retries.

**What it guarantees.** Idempotent consumption, replay safety, durable ingestion, crash recovery.

**Deduplication** is usually `event_id UNIQUE`, or `SETNX(eventId)` in Redis. See [[idempotency]].

---

## Side by side

| Pattern | Purpose | Direction |
| --- | --- | --- |
| Outbox | reliable publishing | outgoing |
| Inbox | reliable consumption | incoming |

> [!tip] The mental model
> Outbox is my service to the external world. Inbox is the external world to my service.

---

## The common real architecture

```text
Webhook
  |
Inbox
  |
Business Logic
  |
Outbox
  |
Kafka
```

Very common in fintech, e-commerce, banking and order systems. See [[webhook-ingestion]] for the receiving end built this way.

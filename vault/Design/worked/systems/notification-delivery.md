# Fault Tolerant Notification Delivery

> [!tldr]
> The API captures intent synchronously and returns fast. Kafka handles execution, buffering and retries. Neither can replace the other.

---

## Reframe the problem first

> [!tip] Say this early
> We need a reliable, scalable, asynchronous notification system that guarantees at least once delivery, tolerates provider failures, and supports high throughput with observability. This is an event driven system that prioritises at least once delivery, fault tolerance and scalability over real time guarantees.

This is not "send email". It is distributed systems, event processing, failure isolation and [[backpressure]].

---

## Requirements

**Functional.** Send via email or SMS, support multiple providers, respect user preferences, and track the lifecycle `PENDING -> SENT | FAILED | DEAD`. Operationally, retry failures, prevent message loss, and support bulk and burst traffic.

**Non functional.**

| Requirement | Why |
| --- | --- |
| At least once delivery | message loss is unacceptable |
| Horizontal scalability | millions per day |
| Fault isolation | a provider outage is not a system outage |
| Ordering per notification | avoid duplicate sends |
| Observability | debugging and [[sli-slo-and-sla|SLA]] |

---

## The architecture

```text
Client
  |
  v
Notification API  (sync, fast)
  |
  v
Database (source of truth)
  |
  v
Kafka Topics
  |
  v
Consumers / Workers
  |
  v
Provider Adapter Layer
  |
  +--> Email Provider
  +--> SMS Provider
```

### Why both the API and Kafka exist

This is the key interview point.

**The API does** validation, auth, preference checks, the durable database write, and returns `202 Accepted`.

**Kafka does** async execution, buffering traffic spikes, decoupling producers from consumers, retries, replay, DLQ and horizontal scale.

They solve different problems, and one cannot replace the other.

---

## Kafka design

| Topic | Purpose |
| --- | --- |
| `notification.requests` | new notifications |
| `notification.retries` | failed notifications |
| `notification.dlq` | permanently failed |

**Partition key.** `notification_id`, which guarantees ordering per notification and prevents concurrent duplicate sends.

**Consumer group.** `notification-sender-group`, with Kafka handling load balancing.

---

## The schema

```sql
notifications (
  notification_id UUID PRIMARY KEY,
  user_id UUID,
  channel ENUM(email, sms),
  provider ENUM(...),
  template_id UUID,
  payload JSONB,
  status ENUM(pending, sent, retrying, failed, dead),
  retry_count INT,
  idempotency_key STRING,
  created_at TIMESTAMP,
  last_attempt_at TIMESTAMP
)

user_notification_preferences (
  user_id UUID,
  channel ENUM(email, sms),
  enabled BOOLEAN
)
```

Preferences are cached heavily.

> [!question] Why a database at all when you have Kafka?
> Kafka is not long term state. The database gives auditability, idempotency and replay safety.

---

## The API

```text
POST /notifications

{
  "userId": "123",
  "channel": "email",
  "templateId": "welcome_v1",
  "payload": { "name": "Rahul" }
}
```

The response is `202 Accepted`.

> [!warning] Never return 200
> Delivery is asynchronous. Returning 200 claims something you have not done. See [[http-status-codes]].

---

## The producer flow

Validate the request, check user preferences, insert into the database with status pending, publish to Kafka, return 202.

**The database write comes before the Kafka publish**, which prevents ghost messages.

Better still, use the transactional outbox:

```sql
BEGIN;
INSERT INTO notifications (status = 'PENDING', ...);
INSERT INTO outbox_events (...);
COMMIT;
```

There is no Kafka call inside the transaction at all. See [[distributed-transactions]].

---

## The consumer

```text
poll()
 -> deserialize message
 -> check idempotency
 -> call provider
 -> update DB
 -> commit offset
```

**Offset commit strategy.** Commit manually, only after the database update succeeds. A crash before the commit means the message is reprocessed, which is what gives at least once delivery. See [[consumer-groups-and-offsets]].

---

## Retries

When the provider fails: increment `retry_count`, publish to `notification.retries` with a delay, and commit the offset.

> [!tip] The line about delays
> Kafka does not support native delayed messages, so we model delay using retry topics or a scheduler.

The options are delay topics such as `retry-10s` and `retry-1m`, a scheduler service, or a Redis delay queue. See [[polling-and-pausing]].

| Attempt | Delay |
| --- | --- |
| 1 | 10s |
| 2 | 30s |
| 3 | 2m |
| 4 | 10m |
| 5 | DLQ |

**The DLQ** catches invalid addresses, exceeded retries and permanent provider errors. It prevents infinite retries, enables manual inspection, and preserves system health.

---

## The provider adapter layer

```text
send(notification):
  try the primary provider
  if it fails -> fallback provider
  apply a circuit breaker
```

Each provider has its own retry policy, its own circuit breaker and its own metrics. See [[circuit-breaker]].

---

## Idempotency

Kafka retries mean duplicate sends. The key is `hash(notification_id + channel)`, stored in the database and checked before sending.

---

## What goes wrong in production

**Kafka lag builds up.** Consumers are slower than producers. Scale the consumer group, apply backpressure at the API layer, and alert on lag.

**Provider partial failure.** The API returns 200 but the message is never delivered. Use provider delivery receipts and reconciliation jobs.

**The database becomes the bottleneck.** Retries cause [[write-amplification|write amplification]]. Batch the updates, make status updates async, and split read and write.

**[[poison-message|Poison messages]].** A bad payload always fails. Use schema validation and route to the DLQ after max retries.

**Retry storm after recovery.** Everything retries the moment the provider comes back. Apply exponential backoff plus jitter. See [[exponential-backoff]].

---

## Observability

**Metrics.** Kafka consumer lag, success and failure rate, retry counts, DLQ size, provider latency.

**Alerts.** A DLQ spike, provider error rate, retry backlog.

**Logs.** Correlated by `notification_id` as the trace key.

---

## The one line summary

> [!tip] Gold
> We use an API to synchronously capture and validate intent, persist state, and return a fast acknowledgement, while Kafka handles asynchronous execution, buffering, retries and scalability to guarantee at least once notification delivery under failure.

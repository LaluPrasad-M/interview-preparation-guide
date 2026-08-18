# Idempotent APIs and Designing for Failure

> [!tldr]
> An API is idempotent if multiple identical requests leave the system in the same final state as a single request. The focus is side effects, not responses.

---

## Why it is required

Retries happen for real reasons: network timeouts, client retries, load balancer retries, flaky mobile networks, and at least once delivery from a queue.

Without idempotency you get duplicate orders, double payments and corrupt state. With it you get safe retries and an exactly once effect.

---

## HTTP methods

| Method | Idempotent | Safe | Cacheable | Notes |
| --- | --- | --- | --- | --- |
| GET | yes | yes | yes | read only, changes nothing on the server |
| PUT | yes | no | no | replaces the resource, so the same request gives the same final state |
| DELETE | yes | no | no | deleting twice gives the same result |
| POST | no | no | no | two POSTs create two resources |
| PATCH | no | no | no | depends on implementation, `set status = paid` is idempotent, `add 10 to balance` is not |

Safe means the request does not change server state, which is why a browser or crawler will fire a GET without asking and will not fire a POST.
Cacheable follows from that: a proxy or [[cdn|CDN]] can hold a GET response, and has nothing safe to hold for the rest.

POST is the main problem in production systems.
The properties above are what decide whether a retry is allowed at all, and retries are not optional: clients time out, load balancers resend, and Kafka delivers at least once.

---

## The techniques

### 1. The idempotency key, the most important

The client sends a unique key per logical operation, and the server stores the result against that key.

```text
POST /payments
Idempotency-Key: uuid-123
```

```text
if key exists -> return the stored response
else         -> process, then store the response
```

### 2. Deterministic resource identifiers

Instead of `POST /orders`, use `PUT /orders/{orderId}`. The same ID gives the same final state, so retries are naturally safe.

### 3. Database constraints, the mandatory safety net

Unique indexes prevent duplicates even when the application logic fails.

```sql
UNIQUE(user_id, external_order_id)
```

Never rely only on application logic.

### 4. Upserts instead of inserts

```sql
INSERT ... ON CONFLICT DO NOTHING
INSERT ... ON DUPLICATE KEY UPDATE
```

### 5. Idempotent state transitions

```js
// Bad
chargeCard()
order.status = PAID

// Good
if (order.status !== PAID) {
  chargeCard()
  order.status = PAID
}
```

Side effects must happen once per state transition.

---

## Handling partial failures

Maintain an idempotency record with a state of `IN_PROGRESS`, `SUCCESS` or `FAILED`.

On retry: `SUCCESS` returns the cached response, `IN_PROGRESS` waits or returns 202 or 409, and `FAILED` retries safely.

---

## Idempotency in async systems

Kafka is at least once, so the consumer must be idempotent. Deduplicate using the event ID and track processed events.

```js
if (processedEventIds.has(event.id)) return;
process(event);
markProcessed(event.id);
```

See [[consumer-groups-and-offsets]] for the four deduplication strategies in full.

---

## The generic failure handling checklist

Run through this in order whenever designing any API.

### 1. Retry safety

**Ask.** If the client retries, will the system duplicate side effects?

**Tools.** Idempotency key, unique constraint, PUT semantics, idempotent background job.

**The fundamental.** Idempotency, and consistency via constraints.

### 2. Concurrency control

**Ask.** What if two requests modify the same resource simultaneously?

**Tools.** Unique index, optimistic locking with a version field, pessimistic locking with `SELECT FOR UPDATE`, atomic update conditions.

**The fundamental.** Isolation, preventing the lost update anomaly.

### 3. Atomic multi step updates

**Ask.** If multiple writes must succeed together, how do we guarantee all or nothing?

**Tools.** A database transaction, a multi document transaction in Mongo, two phase commit rarely, or a saga across microservices.

**The fundamental.** Atomicity and durability, meaning [[write-ahead-log|WAL]] in SQL and journaling in Mongo.

### 4. Partial failure of external services

**Ask.** What if the external service succeeds but the database fails?

**Tools.** A state machine, a reconciliation job, the outbox pattern, event driven retry.

**The fundamental.** Eventual consistency and the at least once delivery model. See [[distributed-transactions]].

### 5. Background job duplication

**Ask.** What if the job runs twice?

**Tools.** Unique constraint, idempotent processing logic.

**The fundamental.** Deterministic state transition.

### 6. Timeout and downstream failure

**Ask.** What if a dependency is slow or down?

**Tools.** Timeout, retry with [[exponential-backoff|backoff]], circuit breaker.

**The fundamental.** Availability over consistency, and failing fast. See [[service-layer]].

### 7. System overload

**Ask.** What if traffic spikes?

**Tools.** Rate limiting, [[debouncing-and-throttling|throttling]], queue buffering.

**The fundamental.** [[backpressure|Backpressure]], and protecting availability. See [[fault-tolerance]].

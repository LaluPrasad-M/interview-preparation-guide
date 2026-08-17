# Webhook Delivery Engine

> [!tldr]
> Never sleep in a consumer to retry. Publish to a delay topic and move on, so one failing tenant cannot block the queue for everyone else.

---

## The webhook primer: caller against callee

A normal API is pull. The client asks the server for data. A webhook is push, a reverse API. The server has new data, so it automatically sends an HTTP POST to the client's URL.

**Scenario A, we are the caller, the sender.** A patient booked with us and the hospital needs to know. They give us a URL and we push the JSON to them. Our responsibility is to handle retries if they are down, respect their rate limits, and never accidentally send the same appointment twice.

**Scenario B, we are the callee, the receiver.** A doctor cancels an appointment in their system and they need to tell us. We give them a URL and they push JSON to us. Our responsibility is to reply `200 OK` in milliseconds so they do not time out, validate their HMAC signature so a hacker cannot send fake cancellations, and deduplicate the event if they send it twice.

This design is scenario A. See [[webhook-ingestion]] for scenario B, and [[webhook-signatures]] for the HMAC mechanics.

---

## The problem

A patient books an appointment on our app, but the doctors do not use our app. They look at their own legacy hospital software.

We need to send our appointment data over the internet to their system via a webhook. But their system is old. It crashes often, goes down for midnight maintenance, and blocks us if we send data too fast.

**The objective.** Build a highly reliable asynchronous pipeline that tries to send the appointment, and if it fails puts it into a retry loop with increasing delays of 1 minute, 15 minutes, 1 hour. If it fails completely, it safely parks the data in a dead letter queue so no patient record is ever lost.

---

## Functional requirements

**Ingest.** Detect when a new appointment is finalised in our database.

**Dispatch.** Send the appointment data as an HTTP POST to the external webhook URL.

**Retry.** If the webhook returns a 500 error or times out, automatically retry later.

**Quarantine.** After 5 failed retries, move the record to a dead letter queue so a support engineer can manually fix it.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | moderate, 1,000 to 5,000 requests per minute. The focus is reliability, not throughput |
| Performance | async delivery. 3 to 5 seconds normally is fine, or several hours if the hospital is in maintenance |
| Availability against consistency | absolute durability and zero data loss. We guarantee at least once delivery and never drop a message |
| Concurrency and isolation | tenant isolation. If one hospital goes down and backs up our retry queues, another must keep receiving messages instantly |
| Edge cases | the external webhook has strict rate limits, for example 10 requests per second |

---

## The retry topology

```text
======================= INGESTION BOUNDARY ==========================

      +-------------------------------------------+
      |   APPOINTMENT ORCHESTRATOR (Our Backend)  |
      +---------------------+---------------------+
                            | 1. CDC via Debezium (Outbox pattern)
                            v
           +------------------------------------------------------------+
           |                   APACHE KAFKA                             |
           | Topic: core.appointments.booked                            |
           | Partition Key: tenant_id                                   |
           +------------------------+-----------------------------------+
                                    | 2. ASYNC Poll
                                    v
============= DISPATCH, RETRY AND WEBHOOK BOUNDARY =======================

  +-----------------------------------------------------------+
  |             EHR WEBHOOK DISPATCHER (Node.js)              |
  |               (Rate-limited consumer group)               |
  +-------+-------------------------+-----------------+-------+
          |                         |                 |
          | 3a. Success (200 OK)    | 3b. Fails (503) | 3c. Fails 5 times
          v                         v                 v
  +---------------+        +------------------+  +------------------+
  | HOSPITAL EHR  |        |   KAFKA RETRY    |  | DEAD LETTER QUEUE|
  | WEBHOOK URL   |        |     TOPICS       |  |      (DLQ)       |
  | (External API)|        | - tenant_retry_1m|  | - tenant_dlq     |
  +---------------+        | - tenant_retry_1h|  | (Manual ops view)|
                           +--------+---------+  +------------------+
                                    | 4. Re-polled after delay
                                    v
                           (Back to dispatcher)
```

---

## The data flow

**1. The safe handoff.** When the appointment is saved in Postgres, the outbox pattern via Debezium pushes it into the main Kafka topic. That guarantees we do not lose the event even if the server crashes immediately after saving.

**2. The dispatcher.** The dispatcher pulls the message from Kafka and looks up the correct URL for that specific hospital.

**3. The webhook attempt.** The dispatcher makes an HTTP POST.

On success it commits the Kafka offset and marks the status `DELIVERED` in our database.

On failure, a 503 or timeout, the dispatcher **does not sleep**, because sleeping blocks the queue. Instead it publishes the same message to a `retry_1m` topic and moves on to the next message.

**4. The retry loop.** A separate worker listens to `retry_1m`. After 1 minute it tries again. If it fails, it pushes to `retry_1h`. That is [[exponential-backoff]]. See [[polling-and-pausing]] for how the delay is actually enforced without dying.

**5. The DLQ.** If the hospital is down for 24 hours, or our payload is missing a required field and returns `400 Bad Request`, retrying will not help. The system pushes the message to the DLQ, an alert fires, and an engineer fixes the JSON and clicks a button to replay it.

---

## The webhook call we make

**Method.** `POST https://ehr.hospital.com/api/v1/appointments`

| Header | Purpose |
| --- | --- |
| `Content-Type: application/json` | |
| `X-Signature: <HMAC_SHA256>` | we sign the payload with a secret key so the hospital knows it is truly from us, not an attacker |
| `Idempotency-Key: apt_12345` | if we time out and retry, the hospital uses this key to realise they already saved this appointment, preventing a double booking on their end |

```json
{
  "event_id": "evt_999",
  "event_type": "appointment.booked",
  "timestamp": "2026-08-06T10:00:00Z",
  "data": {
    "appointment_id": "apt_12345",
    "patient_id": "p_777",
    "slot_time": "2026-08-10T09:00:00Z"
  }
}
```

---

## Database design, state tracking

Kafka is a dumb pipe. You cannot query it to ask "did this appointment sync?". You need a relational table tracking the state of the outbound webhook.

**Table `webhook_delivery_logs`.**

| Column | Notes |
| --- | --- |
| `id` | UUID, primary key |
| `appointment_id` | UUID, indexed |
| `tenant_id` | VARCHAR |
| `status` | enum: `PENDING`, `DELIVERED`, `RETRYING`, `DLQ` |
| `attempt_count` | INT, starts at 1 and increments on failure |
| `last_http_status` | INT, for example 200, 503, 400. Very helpful for debugging |
| `next_retry_at` | timestamp |
| `created_at` | timestamp |

```sql
CREATE INDEX idx_tenant_dlq ON webhook_delivery_logs(tenant_id) WHERE status = 'DLQ';
```

That partial index lets the operations team instantly load a dashboard of failed messages without scanning millions of successful rows.

---

## Trade offs and edge cases

### Delay topics against in memory retries

**The trap.** A junior developer uses a `while` loop with `setTimeout` in the service to retry the webhook.

**The reality.** If the pod restarts, all those in memory retries are permanently lost. And holding connections open blocks the event loop.

**The solution.** Trade architectural complexity, creating multiple Kafka retry topics, for absolute durability. If a pod dies, the message is safe in the retry topic.

### Strict ordering against high throughput

**The reality.** When you push a failed message to a retry topic, newer appointments jump ahead of it in the main topic. Kafka's strict chronological ordering is broken.

**The justification.** In appointment booking, order 2 does not depend on order 1. We gladly sacrifice strict global ordering to ensure one failing hospital webhook does not block the entire queue.

### The hospital's rate limit

**The risk.** They say do not send more than 10 requests per second. If we auto scale our dispatcher to 20 pods, they will blast 200 requests per second and get our IP banned.

**The defence.** Before firing the HTTP POST, the worker checks a Redis token bucket. If the bucket for that tenant is empty, the worker throws a custom `RateLimitException`, which cleanly routes the message to `retry_1m` without hitting the external API at all.

---

## Follow up questions

### Architecting the receiver instead

**Q.** How would you architect the webhook receiver API differently from this sender architecture?

**A.** As the receiver, the primary goal is returning `200 OK` as fast as possible so the sender does not retry. Build a highly optimised gateway that validates the HMAC signature, drops the raw JSON into a Kafka `inbound_webhooks` topic, and immediately returns `202 Accepted`. A background worker picks it up, deduplicates using the sender's `event_id`, and updates PostgreSQL. That lets us absorb a massive burst without dropping connections.

### A hospital down for 12 hours

**Q.** Our retry topics keep looping, doing useless work and wasting CPU.

**A.** Implement the circuit breaker pattern. If the dispatcher detects 10 consecutive 503 timeouts for a tenant, it trips the breaker to open and pauses polling messages for that tenant entirely. After 5 minutes it moves to half open and lets 1 test message through. If that succeeds, the breaker closes and normal processing resumes.

That prevents our system from hammering a downed hospital and saves our own CPU.

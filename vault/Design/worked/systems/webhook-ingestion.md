# Webhook Ingestion Engine

> [!tldr]
> Accept fast, queue, and let the database resolve duplicates and out of order events. The whole design collapses into one clever `INSERT ... ON CONFLICT` query.

---

## The problem

A CRM sends HTTP POST webhooks to our system whenever a contact is created or updated.

The provider demands a response in under 5 seconds. Networks are chaotic, so an update event might arrive before a create event. And the provider guarantees at least once delivery, meaning it will frequently send the exact same event twice.

**The objective.** A high throughput ingestion pipeline that acts as a shock absorber, safely queues events, and uses idempotent database operations to resolve out of order and duplicate data silently.

---

## Functional requirements

**Ingest.** Expose a public endpoint to receive the payloads.

**Security.** Validate the signature HMAC hash to ensure the payload is not forged.

**Process.** Create or update the contact in our internal PostgreSQL database.

**Resilience.** Ignore duplicate events and discard older, stale updates that arrive late.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | highly bursty. Marketing blasts can trigger 100,000 events in a few seconds |
| Performance | the ingestion API must respond in under 100 ms, well under the 5 second limit |
| Availability against consistency | availability for the ingestion API, which must never go down, but eventual consistency for the database processing |
| Concurrency | multiple consumers processing webhooks for the same `contact_id` simultaneously |

---

## The architecture

```text
======================= PHASE 1: INGESTION (SYNC) =======================

      +-------------------------------------------+
      |               SOURCE CRM                  |
      +---------------------+---------------------+
                            | 1. POST /v1/webhooks/crm
                            v
      +-------------------------------------------+
      |   WEBHOOK RECEIVER API (Node.js/Go)       |
      |   (Validates HMAC Signature)              |
      +------+------------------------------+-----+
             |                              |
 2. Return   |                              | 3. Publish Event
 202 Accepted|                              v
      +------+--------------------+ +--------------------------------+
      | Source stops retrying.    | | KAFKA: crm.contacts.raw        |
      | We now own the data.      | | Partition Key: contact_id      |
      +---------------------------+ +---------------+----------------+
                                                    |
======================= PHASE 2: PROCESSING (ASYNC) ======================

                                                    | 4. Poll
                                                    v
      +-------------------------------------------+ 5. Fails (DB Down)
      |      CONTACT PROCESSOR WORKERS            +--------+
      +------+------------------------------+-----+        |
             |                              |              v
             | 6. Upsert to DB              |     +--------------------+
             v                              |     | KAFKA RETRY TOPICS |
  +-------------------+                     |     | - retry_1m         |
  | POSTGRESQL        |                     |     | - dlq (dead letter)|
  | (Source of Truth) |                     |     +--------------------+
  +-------------------+                     |
      Handles out-of-order                  | 7. Commit Kafka Offset
      and duplicates natively.              v
```

---

## The data flow

**1. Ingestion.** The source fires a JSON payload. The receiver catches it, hashes the body with our shared secret, and compares it to the signature header.

**2. The buffer.** If valid, the receiver drops the raw JSON into the Kafka topic `crm.contacts.raw`.

> [!warning] The crucial detail
> The Kafka partition key must be the `contact_id`. That guarantees all updates for one contact go to the same partition, so they are processed by the same worker in chronological order, which naturally solves most out of order issues.

**3. The acknowledgement.** The receiver returns `202 Accepted`.

**4. The processing.** The consumer worker polls the topic and extracts the contact data and the `occurredAt` timestamp.

**5. The idempotent write.** The worker attempts an upsert against PostgreSQL, using a timestamp check to drop duplicates and stale events instantly.

**6. Internal retries.** If PostgreSQL is locked or returning 500s, the worker catches the error, publishes to `crm.retry_1m`, and commits the offset on the main topic. That prevents the queue backing up while guaranteeing no data loss. See [[polling-and-pausing]] for how the delayed retry topics actually work.

---

## API design

**Endpoint.** `POST /v1/webhooks/crm/contacts`

**Headers.** `X-Webhook-Signature-v3: <hash>`

```json
[
  {
    "eventId": "evt_9988",
    "subscriptionType": "contact.creation",
    "objectId": 123456,
    "occurredAt": 1691234567890,
    "properties": {
      "email": "john@example.com",
      "firstname": "John"
    }
  }
]
```

Providers often send webhooks in arrays, as batches. The receiver iterates the array and publishes each event as an individual Kafka message.

---

## Database design, the secret sauce

If you write `if/else` logic in the application to check whether an event is older than what is in the database, you will hit race conditions. Let the database handle it with optimistic concurrency.

**Table `contacts`.**

| Column | Notes |
| --- | --- |
| `crm_id` | BIGINT, primary key |
| `email` | VARCHAR |
| `first_name` | VARCHAR |
| `last_crm_update_at` | BIGINT, stores the `occurredAt` timestamp from the webhook |

### The magic upsert

```sql
INSERT INTO contacts (crm_id, email, first_name, last_crm_update_at)
VALUES (123456, 'john@example.com', 'John', 1691234567890)
ON CONFLICT (crm_id)
DO UPDATE SET
   email = EXCLUDED.email,
   first_name = EXCLUDED.first_name,
   last_crm_update_at = EXCLUDED.last_crm_update_at
-- THE OUT-OF-ORDER SHIELD:
WHERE contacts.last_crm_update_at < EXCLUDED.last_crm_update_at;
```

**Why this is brilliant.**

**Duplicates.** If the same event arrives twice, `1691234567890 < 1691234567890` is false, so the database does nothing. Idempotency achieved.

**Out of order.** If a create event from 10:00 arrives after an update event from 10:05, `10:00 < 10:05` is false, so the database ignores the stale data. Ordering achieved.

See [[out-of-order-events]] for the general pattern.

---

## Many providers, not one

This note gets away with a single `contacts` table because there is one provider and one event shape. A general receiver fielding a calendar provider, a payment provider and an email provider on the same endpoint needs to persist the raw event first, before anything downstream touches it.

**Table `webhook_events`.**

| Column | Notes |
| --- | --- |
| `id` | UUID, primary key |
| `provider` | TEXT, for example `stripe` or `google_calendar` |
| `external_event_id` | TEXT, the provider's own event ID |
| `company_id` | UUID, which tenant the event belongs to |
| `payload` | JSONB, the raw event body |
| `status` | enum: `RECEIVED`, `PROCESSING`, `DONE`, `FAILED` |
| `retry_count` | INT |
| `created_at`, `processed_at` | timestamps |

**Constraint.** `UNIQUE(provider, external_event_id)`. A unique index on `external_event_id` alone breaks the day two providers coincidentally hand out the same ID, so the pair is the real key.

**Why the `status` column.** It is not there for the write path. It is there for the two questions that come later: which rows need a retry, and did this specific event ever finish processing, without grepping logs to find out.

This is the outbox shape from [[distributed-transactions]]: insert the event row and an outbox row in one transaction, then let a poller move it to Kafka, so a crash between the insert and the publish cannot lose the event or silently double publish it.

---

## Trade offs

### Kafka partitioning against round robin

**The trap.** Sending events to Kafka with round robin, no partition key, maximises throughput. But update 1 for a contact might go to worker A and update 2 to worker B, and worker B might process update 2 before worker A processes update 1.

**The solution.** Partition by `contact_id`. This restricts throughput slightly but guarantees all events for a single contact are processed by a single worker thread in the order they entered Kafka.

### 202 Accepted against 200 OK

`200 OK` implies "I have successfully processed and saved this data". `202 Accepted` means "I have received the payload and queued it for asynchronous processing". This note returns 202, because if the contact fails our internal validation later, we cannot notify the source via this synchronous connection, and 202 keeps that gap honest.

> [!warning] The other valid answer is 200, and it is a real trade off
> | Code | Tells the caller | Pick it when |
> | --- | --- | --- |
> | `202 Accepted` | "received, not yet processed" | you want the response code to stay honest about what has actually happened, and the provider does not retry aggressively on anything but a 200 |
> | `200 OK` | "accepted, stop retrying" | the provider hammers the endpoint on anything but 200, and your `UNIQUE(provider, external_event_id)` constraint already makes a duplicate harmless, so there is nothing left to protect by staying strictly honest |
>
> A stricter receiver handling several providers, some of which retry hard on non 200 responses, will often return 200 even on a detected duplicate for exactly this reason. If an interviewer asks "why 202 and not 200", this table is the answer: it depends on how the specific provider behaves when it does not see a 200.

---

## Observability

**Watch these.** Webhook QPS per provider, signature failure rate, duplicate rate, Kafka consumer lag, DLQ count.

A spike in signature failure rate means either a secret rotated without you knowing or someone is probing the endpoint. A spike in duplicate rate is usually just a provider's retry storm, not a bug, so alert on a sudden change in the rate rather than on any duplicate existing at all.

---

## Follow up questions

### Five updates for one contact in two seconds

**Q.** Our consumer will hit Postgres 5 times. Can we optimise this?

**A.** Yes, with micro batching or debouncing. The consumer pulls a batch of 5,000 messages into memory, groups the array by `contact_id`, and if it finds 5 updates for the same ID it keeps only the object with the highest `occurredAt`, discarding the other 4 in memory. Then it performs a bulk upsert, drastically reducing DB load.

### A hacker spams the endpoint

**Q.** What if someone discovers our endpoint and spams it with millions of fake webhooks to DDoS our database?

**A.** Because we validate the signature at the receiver API, at the edge, any payload lacking the correct cryptographic signature is instantly dropped with `401 Unauthorized`. It never enters Kafka and never reaches the database. To protect the receiver itself from volumetric DDoS, we rely on the API gateway or WAF to rate limit by IP.

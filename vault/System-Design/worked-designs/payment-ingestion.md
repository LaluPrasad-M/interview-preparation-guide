# Idempotent Payment Ingestion

> [!tldr]
> Three layers of defence against a double charge: a Redis lock, a Kafka partition key, and a unique constraint in Postgres. Each one exists because the layer above it can fail.

---

## Who we are in this design

We are the merchant backend, the middleman. We are the servers for a large e-commerce or ticket booking platform.

The sender is the user clicking pay on our mobile app. The receiver is the external payment service provider.

**Why we exist.** The mobile app cannot talk directly to the provider to finalise a payment. The app tells our backend to deduct the money. Our backend records the order, securely contacts the provider to process the charge, and ensures that if the user's internet flickers and they click pay three times, we only charge them once.

---

## Functional requirements

**Client actions.** Initiate a payment using a stored payment method or token. Poll the system for the status of a pending payment, since the UI needs a loading spinner.

**System actions.** Safely absorb massive traffic spikes without dropping requests or crashing the database. Enforce strict idempotency. Securely communicate with the external provider to execute the financial capture. Transition internal payment states sequentially: `PENDING` to `PROCESSING` to `SUCCESS` or `FAILED`.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | write heavy ingestion path, with flash sale bursts of 10,000 to 50,000 RPS |
| Performance | return `202 Accepted` in under 50 ms at p99. Calling the provider takes 2 to 5 seconds, and waiting synchronously would exhaust all server connections |
| Availability against consistency | the gateway and ingestion service prioritise availability, so if the provider is down we still accept and buffer the order. The financial record in PostgreSQL requires strong consistency |
| Concurrency | high risk of race conditions if identical requests arrive in the same millisecond, so we use atomic locks to serialise them |
| Durability | zero data loss. Once we return 202, the event must be durably written to Kafka with `acks=all` |
| Edge cases | Kafka consumer crashes mid processing creating zombie states, and poison pill messages that crash consumers repeatedly |

---

## The architecture

```text
==================== SYNC INGESTION BOUNDARY (< 50ms) ======================

      +-------------------------------------------+
      |        CLIENT (Mobile / Web App)          |
      +---------------------+---------------------+
                            | 1. POST /v1/payments (Sync HTTPS)
                            | Payload: {amount: 5000, idemp_key: "abc-123"}
                            v
      +-------------------------------------------+
      |               API GATEWAY                 |
      |         (Auth and Rate Limiting)          |
      +---------------------+---------------------+
                            | 2. Sync gRPC Route
                            v
      +-------------------------------------------+
      |       PAYMENT INGESTION SERVICE           |
      |     (Stateless, high throughput API)      |
      +------+------------------------------+-----+
             |                              |
 3. Sync TCP |                              | 4. ASYNC TCP (fire and forget)
 SETNX       |                              | Topic: payment.requested.v1
 'PENDING'   |                              | Partition Key: user_id
             v                              v (requires acks=all)
  +--------------------+         +--------------------+
  |   REDIS CLUSTER    |         |    APACHE KAFKA    |
  | (Hot deduplication)|         |  (Shock absorber)  |
  +----------+---------+         +----------+---------+
             |                              |
=============|====== ASYNC PROCESSING BOUNDARY (2 to 5 seconds)============
             |                              |
 4. Sync TCP |                              | 5. ASYNC TCP (Poll)
 SET         |                              | Group: payment_processors
 'SUCCESS'   |                              v
             |           +----------------------------------+
             +-----------+    PAYMENT CONSUMER WORKERS      |
                         |      (Idempotent processors)     |
                         +------+---------------------+-----+
                                |                     |
                  6. Sync HTTPS |                     | 7. Sync TCP (PgSQL)
                  POST /charges |                     | INSERT INTO payments
                  Header:       |                     | Constraint:
                  Idemp-Key     |                     | UNIQUE(idemp_key)
                                v                     v
                 +--------------------+    +---------------------+
                 |  PAYMENT PROVIDER  |    | POSTGRESQL PRIMARY  |
                 |   (External API)   |    |  (Source of Truth)  |
                 +--------------------+    +---------------------+

 [Background] ---> Reconciliation cron job, scans DB for stuck PENDING rows
```

---

## Component walkthrough

**The sync boundary.** If you connect the API directly to PostgreSQL or the provider, a flash sale exhausts your DB connection pool. The top half does a sub millisecond constant time check in Redis, drops the payload in Kafka, and replies instantly. The bottom half handles the slow 5 second provider calls, with Kafka as the shock absorber.

**Redis `SETNX`, the first line of defence.** If a user double clicks pay, two identical requests hit our API. `SETNX` on the idempotency key means the first request gets 1 and proceeds to Kafka, and the second gets 0 and the API instantly returns `409 Conflict`.

**The Kafka partition key, solving concurrency.** By setting the partition key to `user_id`, if a user spams 5 requests they all land in the same partition. Because a partition is read by exactly one worker thread, those 5 requests are processed chronologically, eliminating race conditions.

**The PostgreSQL unique constraint, the ultimate safety net.** Redis is volatile and can crash or evict keys. If Redis loses a key and Kafka replays a message, the worker might try to charge again. The unique constraint means the database physically rejects the duplicate row, throwing a hard SQL error and preventing the double charge.

---

## API design

### The ingestion endpoint, the write path

**Method.** `POST /v1/payments`

**Headers.** `Idempotency-Key: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d`

> [!warning] The key is generated by the client, not the backend
> If the network drops, the phone re sends the same UUID. A server generated key would be different on every attempt, which defeats the whole point.

```json
{
  "user_id": "usr_8899",
  "amount": 15000,
  "currency": "USD",
  "payment_token": "tok_visa_123"
}
```

| Response | Meaning |
| --- | --- |
| `202 Accepted` | validated, hot deduplicated, and buffered in Kafka |
| `400 Bad Request` | missing idempotency key header |
| `409 Conflict` | this key is currently processing or already succeeded |

### The polling endpoint, the read path

Because we returned a 202, the frontend shows a spinner and polls every 2 seconds.

**Method.** `GET /v1/payments/status/{idempotency_key}`

**Response.** `{ "status": "PROCESSING" }` or `{ "status": "SUCCESS", "receipt_url": "..." }`

---

## Database design

We use PostgreSQL, because NoSQL does not enforce cross row uniqueness and ACID compliance as easily.

**Table `payments`.**

| Column | Notes |
| --- | --- |
| `id` | UUID, primary key |
| `idempotency_key` | VARCHAR, **unique index**, this prevents the double charge |
| `user_id` | VARCHAR, indexed for user history lookups |
| `amount` | INTEGER. Never use floats or decimals for money. Store in cents, so 150.00 is `15000`, to prevent rounding errors |
| `currency` | VARCHAR, for example `USD` |
| `status` | enum: `PENDING`, `PROCESSING`, `SUCCESS`, `FAILED` |
| `provider_charge_id` | VARCHAR, nullable, the provider's receipt ID |
| `created_at` | timestamp |

---

## Trade offs and edge cases

### 202 Accepted against 200 OK

We explicitly trade user experience, forcing the frontend to implement a polling or WebSocket loading spinner, to achieve massive backend scalability. If we kept the connection open while waiting for the provider, our servers would run out of RAM and threads under flash sale load.

### The zombie payment, a crash before the DB commit

**Scenario.** The Kafka worker charges the provider successfully, then crashes before the `INSERT` into PostgreSQL.

**Solution.** The Kafka offset is not committed, so another worker picks up the message and retries. Because we passed our idempotency key to the provider, the provider recognises the duplicate, does not charge the card again, and returns the original receipt. The new worker then successfully writes to PostgreSQL.

### The stuck PENDING state

**Scenario.** A worker crashes midway. The Redis key is stuck on `PENDING` forever and the user is frozen.

**Solution.** A background reconciliation cron runs every 5 minutes, querying `SELECT * FROM payments WHERE status = 'PENDING' AND created_at < NOW() - 5 minutes`. It takes those IDs, queries the provider directly with `GET /charges/{id}`, and self heals the database based on the provider's real truth.

### The poison pill

**Scenario.** A malformed JSON payload bypasses validation but crashes the Kafka worker. The worker crashes, restarts, reads the message again, and crashes infinitely.

**Solution.** A dead letter queue. If a message crashes the worker 3 times it is automatically routed to a separate topic, `payments.dlq`. That clears the pipeline so legitimate payments proceed, and alerts an engineer to inspect the bad payload. See [[lag-and-dead-letter-queues]].

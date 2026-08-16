# Campaign Execution and Messaging Engine

> [!tldr]
> Tiered topics solve the noisy neighbour problem that a single partition key cannot. Micro batching on the way back keeps 500,000 delivery receipts from killing the database.

---

## The problem

A marketing agency selects 500,000 contacts, drafts an SMS, and clicks send now.

1. Loading 500,000 rows into RAM causes an out of memory crash.
2. Blasting 500,000 simultaneous HTTP requests to the SMS provider triggers a `429 Too Many Requests` ban.
3. The provider then fires 500,000 asynchronous webhooks back saying delivered. Updating PostgreSQL 500,000 times individually exhausts database connections and crashes the database.

**The objective.** A distributed fan out engine that breaks a massive campaign into individual tasks, strictly throttles outbound traffic to match provider limits, guarantees we never double text a user, and absorbs half a million incoming webhooks gracefully.

---

## Functional requirements

**Ingest.** Accept a campaign request and return success to the user instantly.

**Fan out.** Break the campaign into individual trackable messages.

**Dispatch.** Send messages to the provider API at a strictly controlled rate.

**Tracking.** Receive delivery receipts and update the database so the agency dashboard reflects real time statistics.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | massive processing spikes, for example 100,000 internal tasks generated per second |
| Performance | purely asynchronous. The UI gets `202 Accepted` instantly, and processing may take minutes or hours |
| Availability against consistency | exactly once semantics. We absolutely cannot send a promotional text to the same person twice |
| Concurrency | safe state management during massive parallel processing and network failures |
| Edge cases | complete provider outages, OOM crashes during fan out, and the noisy neighbour problem |

---

## The Kafka partitioning dilemma

**If you use `message_id` or round robin**, Kafka evenly distributes the 500,000 messages across all 100 partitions, so all 100 workers process this single campaign simultaneously.

The pro is maximum speed for agency A. The con is that if agency B logs in 5 seconds later and sends a campaign of 100 messages, those get stuck behind agency A's 500,000 across all partitions. Agency B's tiny campaign takes an hour. That is the noisy neighbour problem.

**If you use `agency_id` or `campaign_id`**, all 500,000 messages for agency A are forced into exactly one partition.

The pro is strict tenant isolation, so agency B hashes to an empty partition and sends instantly. The con is that agency A's 500,000 messages are now processed by exactly one worker thread, taking hours.

> [!tip] The solution: tiered topics
> Do not use a simple partition key. Route massive blasts, above 10k messages, to a `campaign.bulk` topic, and small campaigns to a `campaign.express` topic. That guarantees fast processing for small users while allowing parallel round robin processing for massive blasts.

---

## The architecture

```text
=================== PHASE 1: INGESTION AND TRIGGER ========================

      +-------------------------------------------+
      |             AGENCY WEB APP                |
      +---------------------+---------------------+
                            | 1. POST /v1/campaigns
                            v
      +-------------------------------------------+  2. DB: status='PENDING'
      |            CAMPAIGN API (Node.js)         +--------+
      +---------------------+---------------------+        |
                            | 3. Publish trigger event     v
                            v                   +--------------------+
           +---------------------------------+  | POSTGRESQL         |
           | KAFKA TOPIC: campaign.triggers  |  | (Campaign state)   |
           | (Partition Key: campaign_id)    |  +--------------------+
           +----------------+----------------+
                            | 4. Poll
                            v
======================= PHASE 2: FAN-OUT ENGINE ========================

      +-------------------------------------------+
      |       FAN-OUT WORKER (Cursor Paging)      |
      | (Reads contacts, creates individual tasks)|
      +------+------------------------------+-----+
             |                              |
             | 5a. Publish Bulk             | 5b. Publish Express
             v                              v
  +----------------------+       +----------------------+
  | TOPIC: message.bulk  |       | TOPIC: message.fast  |
  | (No partition key,   |       | (No partition key,   |
  |  round-robin to all) |       |  round-robin to all) |
  +----------+-----------+       +----------+-----------+
             | 6. Poll                      |
             v                              v
=================== PHASE 3: DISPATCH AND IDEMPOTENCY =====================

      +-------------------------------------------+  7. Check rate limit
      |   DISPATCH WORKERS (Rate-limited pool)    +--------+
      +---------+-------------------------+-------+        |
                |                         |                v
   8. API Call  |                         |       +--------------------+
  (Send SMS)    v                         |       | REDIS CLUSTER      |
  +-------------------+                   |       | 1. Provider rate   |
  |   SMS PROVIDER    |                   |       |    limiter         |
  |   (3rd party)     |                   |       | 2. SETNX lock      |
  +---------+---------+                   |       +--------------------+
            |                             | 9. Update Postgres: status='SENT'
            |                             v 10. Commit Kafka offset
=================== PHASE 4: WEBHOOKS AND MICRO-BATCHING ==================

            | 11. Webhook HTTP POST       +------------------------------+
            | "Message Delivered"         | KAFKA TOPIC: webhook.events  |
            v                             +---------+--------------------+
  +-------------------+                             |
  | WEBHOOK RECEIVER  | 12. Publish event           | 13. Poll (batches of 5000)
  | (Fast 202 API)    +-----------------------------+
  +-------------------+                             v
                                  +----------------------------------+
                                  | MICRO-BATCH WORKER (Node.js)     |
                                  | (Groups updates in memory)       |
                                  +---------+------------------------+
                                            | 14. Single bulk SQL UPDATE
                                            v
                                  +--------------------+
                                  | POSTGRESQL         |
                                  +--------------------+
```

---

## Phase 1: ingestion

**1. The request.** The agency posts a campaign targeted at a list with 500k contacts.

**2. Persistence.** The API inserts a row into `campaigns` with `status = 'PENDING'`. It does not fetch the 500k contacts.

**3. The trigger.** The API publishes a tiny event, `{ "campaign_id": 123, "list_id": 999, "size": 500000 }`, to `campaign.triggers` and returns `202 Accepted` instantly.

---

## Phase 2: the fan out

**4. Cursor pagination, crucial for memory.** The worker executes `SELECT * FROM contacts WHERE list_id = 999 AND id > {last_seen_id} LIMIT 5000`, fetching chunks of 5,000 without expensive `OFFSET` table scans.

**5. Tiered routing.** The worker generates a Kafka task per contact. Because this campaign is 500,000, it routes to `message.bulk` using round robin with no partition key, letting all dispatch workers attack the queue simultaneously. A 50 person campaign routes to `message.fast`, so a tiny campaign is never blocked by the bulk queue.

### Late hydration, why we store instructions and not messages

If you generate the full text string for millions of users up front, you cache gigabytes of heavy string data. Storing just the lightweight JSON instruction, `{user_id: 123, template: "promo", time: 9am}`, consumes megabytes instead.

You hydrate the payload, merging the user's name into the template, in RAM a millisecond before sending the HTTP request.

The roles are strictly defined. **Kafka** safely transports the instructions. **Redis** passively sorts and stores them by time. **Node.js** actively polls Redis, hydrates the payload, and fires the API. See [[appointment-scheduler]] for the delayed dispatch mechanics in detail.

---

## Phase 3: dispatch and the idempotency chain

This is where we guarantee we never double text a user, even if a worker crashes midway.

**6. The rate limit check.** A dispatch worker polls a message and first evaluates a Redis Lua script against the global provider token bucket. If the limit is 500 per second and the bucket is empty, the worker pauses polling for 1 second.

**7. The Redis lock, internal safety.** The worker executes `SETNX msg_123 'PROCESSING' EX 60`. If it returns 0, another worker is already on this message and this one drops it. If it returns 1, the worker owns the lock for 60 seconds.

**8. The external call, external safety.** The worker makes the HTTP POST, and must include `Idempotency-Key: msg_123`.

Why? If the worker crashes after the provider sends the text but before receiving the 200 response, Kafka retries the message. The new worker hits the provider, which reads the idempotency key, realises it already sent, and returns the old `200 OK` without sending a second text.

**9. Finalise.** The worker receives `200 OK`, updates `campaign_messages` to `status = 'SENT'`, and finally commits the Kafka offset.

---

## Phase 4: the webhook storm

**10. Fast ingestion.** The provider blasts 500,000 HTTP POSTs back saying delivered. The receiver does zero database queries. It validates the HMAC signature, drops the raw JSON into `webhook.events`, and returns `202 Accepted` in roughly 5 ms.

**11. Micro batching, database protection.** The micro batch worker consumes from Kafka. Instead of one SQL query per message, it holds events in RAM until it reaches 5,000 events, or 2 seconds pass.

**12. The bulk execute.** One massive transaction:

```sql
UPDATE campaign_messages AS c
SET status = v.status
FROM (VALUES ('msg_1', 'DELIVERED'), ('msg_2', 'BOUNCED')) AS v(id, status)
WHERE c.id = v.id;
```

That updates 5,000 rows in 50 ms. Without micro batching, 5,000 individual queries would lock the table and exhaust the connection pool.

---

## API design

### Create campaign

**POST** `/v1/campaigns/send`

```json
{
  "name": "Summer Sale",
  "contact_list_id": "list_888",
  "message_template": "Hi {{first_name}}, sale ends tonight!",
  "scheduled_time": "2026-08-06T10:00:00Z"
}
```

### Webhook receiver

**POST** `/v1/webhooks/provider/status`

**Headers.** `X-Provider-Signature: <HMAC_SHA256>`, mandatory, preventing spoofed delivery receipts.

```json
{
  "MessageSid": "msg_123",
  "MessageStatus": "delivered",
  "ErrorCode": null
}
```

---

## Database design

**Table `campaigns`.** `id` UUID primary key, `agency_id` UUID indexed, `status` enum of `PENDING`, `FANNING_OUT`, `SENDING`, `COMPLETED`, and `total_contacts` integer.

**Table `campaign_messages`.** `id` VARCHAR primary key, `campaign_id` UUID foreign key indexed, `contact_id` UUID, `status` enum of `QUEUED`, `SENT`, `DELIVERED`, `BOUNCED`, and `updated_at` timestamp.

> [!tip] Use the provider's message ID as the primary key
> When the provider fires the webhook, it only knows its own message ID. If that is not our primary key, or at least uniquely indexed, our micro batch worker has to do a slow table scan to find the row to update.

---

## Trade offs and edge cases

### Real time analytics against database survival

**The trap.** The agency dashboard wants a websocket showing the delivered counter ticking up in absolute real time.

**The reality.** Updating a SQL aggregate 100,000 times a second is impossible.

**The solution.** Micro batching. The trade off is a dashboard delayed by 2 to 5 seconds. The data is eventually consistent, but the database survives.

### The OOM crash during fan out

**The scenario.** The fan out worker pulls 250,000 contacts and the pod runs out of RAM. On restart it starts fanning out from contact 1 again, sending duplicates.

**The solution.** The worker maintains external state. Every time it publishes a chunk of 5,000 messages, it updates a Redis key: `SET campaign_123_checkpoint 'contact_5000'`. On restart the pod reads Redis and resumes the SQL query from there.

---

## Follow up questions

### A hundred pods hitting the same Redis token bucket

**Q.** If 100 dispatch pods all check Redis in the same millisecond, will that overwhelm Redis or cause race conditions in the token count?

**A.** The rate limit logic cannot be a `GET` followed by a `SET`. It must be a Redis Lua script, evaluated atomically in Redis's single threaded event loop.

Furthermore, to avoid a network bottleneck to a single node, we do not request 1 token at a time. Each pod requests a chunk of 50 tokens every second, holds them in local memory and consumes them. That reduces Redis network traffic by a factor of 50.

### A complete provider outage

**Q.** The provider returns 503 for every request. Our workers keep pulling, failing and pushing to the DLQ.

**A.** The circuit breaker pattern. If a worker detects a 50 percent failure rate over 30 seconds, the breaker trips open, the worker stops polling Kafka entirely and stops calling the provider. Kafka safely buffers the messages on disk. After 5 minutes it moves to half open, lets one message through, and if successful closes and resumes full speed polling.

### Poison pills in the webhook pipeline

**Q.** The provider changes their JSON schema unexpectedly and our micro batch worker crashes every time it parses a specific batch of 5,000.

**A.** A dead letter queue. If the worker catches an unhandled parsing exception, it wraps that batch and publishes it to `webhook.events.dlq`, then gracefully commits the offset for the main topic and continues with the next batch. That stops a malformed third party payload from permanently blocking the entire ingestion pipeline.

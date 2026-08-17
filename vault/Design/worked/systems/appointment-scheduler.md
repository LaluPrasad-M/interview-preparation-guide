# High Concurrency Appointment Scheduler

> [!tldr]
> Reject 49,999 losers in Redis RAM before the database ever sees them, then use the outbox pattern so the confirmed booking can never exist without its sync event.

---

## The problem

At 8:00 AM, 500 telehealth slots open and 50,000 patients try to book the same slots simultaneously.

We are the orchestration backend, sitting between the patient's mobile app and the hospital's massive slow electronic health record system.

**The objective.** Safely serialise 50,000 concurrent write requests, grant 500 temporary 10 minute holds so patients can fill out intake forms, and guarantee zero overselling. Once confirmed, reliably sync to the legacy EHR without losing a record if the EHR goes offline.

---

## Functional requirements

**Reserve.** The patient temporarily locks a slot.

**Confirm.** The patient submits intake forms, converting the reservation into a finalised appointment.

**TTL release.** If the patient abandons the app, the 10 minute hold expires and the slot is released.

**EHR sync.** Confirmed appointments are asynchronously synced to the hospital's EHR.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | 50,000 write QPS burst at exactly 8:00:00 |
| Performance | the reserve API must return in under 50 ms at p99 |
| Availability against consistency | strict CP. Double booking a doctor is a critical operational and legal failure, so we reject requests to protect the schedule |
| Concurrency | extreme lock contention risk |
| Edge cases | dual write failures where the DB commits but Kafka fails, legacy EHR downtime, and protected health information |

---

## The architecture

```text
============== PHASE 1: ATOMIC RESERVATION (< 50ms) =====================

      +-------------------------------------------+
      |         PATIENT APP (React/Mobile)        |
      +---------------------+---------------------+
                            | 1. POST /v1/slots/{id}/reserve
                            v
      +-------------------------------------------+
      |     API GATEWAY                           |
      |   (Rate limiting, JWT validation)         |
      +---------------------+---------------------+
                            | 2. Sync gRPC
                            v
      +-------------------------------------------+
      |   APPOINTMENT ORCHESTRATOR (Node.js)      |
      |   (Stateless, auto-scaled K8s pods)       |
      +---------+-------------------------+-------+
                |                         |
    3. Sync TCP |                         | 4. Sync TCP
   (EVAL Lua    |                         | (SETEX reservation:s123
    Script)     v                         v  Value: {p_99} TTL: 600s)
  +-------------------+        +---------------------+
  |   REDIS CLUSTER   |        |    REDIS CLUSTER    |
  |  (Slot counters)  |        | (TTL/session store) |
  +-------------------+        +---------------------+
  Atomic decrement.            Returns reservation_token to client.

============== PHASE 2: CONFIRMATION AND RELIABLE EHR SYNC ==============

      +-------------------------------------------+
      |         PATIENT APP (React/Mobile)        |
      +---------------------+---------------------+
                            | 5. POST /v1/appointments
                            | Headers: X-Reservation-Token, Idempotency-Key
                            v
      +-------------------------------------------+
      |   APPOINTMENT ORCHESTRATOR (Node.js)      |
      +---------------------+---------------------+
                            |
    6. Sync TCP (PgSQL)     |  <-- [THE OUTBOX PATTERN BOUNDARY]
    BEGIN;                  |
    UPDATE slots...         |
    INSERT INTO outbox...   v
    COMMIT;       +-------------------+
                  | POSTGRESQL        |   7. CDC Stream (Debezium)
                  | (Source of Truth) +-------------------------+
                  +-------------------+                         |
                                                                v
           +------------------------------------------------------------+
           |                     APACHE KAFKA                           |
           | Topic: ehr.appointments.sync                               |
           | Partition Key: hash(tenant_id + clinic_id)                 |
           | Retention: 24 Hours (compliance)                           |
           +------------------------+-----------------------------------+
                                    | 8. ASYNC TCP (Poll)
                                    | Consumer Group: ehr-sync-workers
                                    v
                          +---------------------+
                          |   EHR SYNC WORKER   |
                          |  (Rate limited)     |
                          +---------+-----------+
                                    | 9. Sync HTTPS
                                    v
                          +---------------------+
                          | LEGACY EHR API      |
                          +---------------------+
```

---

## Phase 1: the atomic reservation

**1. The click.** 50,000 patients click reserve. The gateway validates their JWT, drops invalid requests, and forwards traffic to the orchestrator pods.

**2. The fast rejection.** The server absolutely does not query PostgreSQL. It sends a Lua script to Redis. The script checks whether `slot_123` is above 0, and if so decrements it to 0 and returns success. For the other 49,999 requests it instantly returns 0. That takes under 2 ms and saves the database from melting.

**3. The lock.** For the winner, the server writes `reservation:slot_123` to a separate Redis instance with a TTL of 600 seconds, generates a secure JWT `reservation_token`, and sends it back to the phone.

---

## Phase 2: confirmation and the outbox pattern

**4. The submission.** The user spends 5 minutes on the intake form, then hits confirm. The app sends the payload with the `reservation_token` to prove they own the lock.

**5. The transaction, critical.** The server validates the token. It must now mark the slot booked in Postgres and trigger a Kafka event. It does not call Kafka directly. Instead it opens one SQL transaction:

```sql
BEGIN;
UPDATE slots SET status = 'BOOKED' WHERE id = 'slot_123';
INSERT INTO outbox_events (event_type, payload)
  VALUES ('APPOINTMENT_SYNC', '{encrypted_intake_data}');
COMMIT;
```

If the DB crashes, both fail. If it succeeds, both succeed. Zero dual write risk.

**6. Change data capture.** Debezium constantly monitors PostgreSQL's write ahead log. The millisecond that transaction commits, it detects the new row in `outbox_events` and streams the payload into Kafka.

**7. Decoupled delivery.** The EHR sync worker polls Kafka, picks up the appointment, decrypts the data, and makes the slow HTTPS call to the legacy system. If that system is down for maintenance, the worker fails and Kafka retains the message for automatic retry. No data is lost, and the user's experience is unaffected.

---

## Why these choices

**Why Redis Lua scripts instead of Postgres `SELECT FOR UPDATE`?** If 50,000 people hit Postgres simultaneously for the same slot, Postgres puts 49,999 connections into a wait queue, locking the database through connection pool exhaustion. A Lua script is evaluated inside Redis's single threaded event loop, so it is perfectly atomic and rejects the 49,999 losers in memory without touching disk I/O.

**Why the outbox pattern?** If the server updates Postgres and then tries `kafka.publish()`, a network blip drops the Kafka connection. Now the patient thinks they are booked but the hospital does not know. Writing the Kafka payload into the database itself as part of the same transaction guarantees atomicity. See [[distributed-transactions]].

**The Kafka partitioning strategy.** Partition key is `hash(tenant_id + clinic_id)`. Partitioning purely by `tenant_id` sends all of one large customer's traffic to a single partition, a hot partition. Appending `clinic_id` spreads that load evenly while ensuring appointments for the same clinic are processed in strict chronological order.

---

## API design

### Reserve the slot

**POST** `/v1/slots/{slot_id}/reserve`

**Headers.** `Authorization: Bearer <JWT>`, `X-Tenant-Id: <tenant>`, and `Idempotency-Key: <UUID>` generated by the mobile app to prevent accidental double clicks holding two slots.

**Payload.** `{ "patient_id": "usr_9988" }`

**201 Created.**

```json
{
  "data": {
    "status": "RESERVED",
    "reservation_token": "res_eyJhbGciOi...",
    "expires_at": "2026-08-06T08:10:00Z"
  }
}
```

**409 Conflict.** `{"error": "SLOT_UNAVAILABLE", "message": "This slot has just been reserved by another patient."}`

### Confirm the appointment

**POST** `/v1/appointments`

**Headers.** `X-Reservation-Token`, which acts as a short lived authorisation to mutate this specific slot, and `Idempotency-Key`.

```json
{
  "slot_id": "slot_123",
  "intake_form": {
    "reason_for_visit": "Persistent cough",
    "insurance_provider": "BlueCross"
  }
}
```

**200 OK.** `{ "data": { "appointment_id": "apt_777", "status": "CONFIRMED" } }`

**403 Forbidden.** `{"error": "RESERVATION_EXPIRED", "message": "Your 10-minute hold has expired."}`

---

## Database design

**Table `slots`, the source of truth.**

| Column | Notes |
| --- | --- |
| `id` | UUID, primary key |
| `tenant_id` | UUID, foreign key, for strict multi tenant isolation |
| `provider_id` | UUID, foreign key |
| `start_time` | TIMESTAMP WITH TIME ZONE |
| `status` | `AVAILABLE`, `LOCKED`, `BOOKED` |
| `patient_id` | UUID, nullable |
| `version` | INTEGER default 0, used for optimistic locking |

### Partial indexes for discovery

Patients only search for available slots, and indexing millions of past appointments wastes RAM.

```sql
CREATE INDEX idx_available_slots ON slots(provider_id, start_time)
WHERE status = 'AVAILABLE';
```

That keeps the index small and fast.

### Optimistic locking

When phase 2 executes the update, we use the `version` column to prevent race conditions without heavy `SELECT FOR UPDATE` pessimistic locks.

```sql
UPDATE slots
SET status = 'BOOKED', patient_id = 'usr_9988', version = version + 1
WHERE id = 'slot_123' AND version = 0 AND status = 'LOCKED';
```

If an admin modified the row while the user was filling out the form, `version` is no longer 0, the update affects 0 rows, and the API throws `409 Conflict`.

**Table `outbox_events`, the Kafka bridge.** `id` UUID primary key, `aggregate_id` UUID, `event_type` VARCHAR, `payload` JSONB holding the encrypted data, and `created_at` timestamp.

---

## Trade offs and edge cases

### Redis availability against Postgres consistency

**Risk.** Redis is volatile. What if a failover happens at exactly 8:00 AM and we lose the `slot:123` counter? Redis might accidentally let a second person lock the slot.

**Defence.** PostgreSQL is the ultimate authority. Because of optimistic locking, when that second person reaches confirmation Postgres physically rejects them. We trade minor Redis volatility for massive throughput, protected by SQL consistency constraints.

We also make Redis itself resilient rather than relying on Postgres to back it up. Run Redis Sentinel, or a managed equivalent, as a highly available cluster with primary and replica nodes spanning multiple availability zones, so if the master dies a replica is promoted in milliseconds. And configure append only file persistence with `appendfsync everysec`, so on restart a node reconstructs the reservation keys from the disk log, losing at most 1 second of data.

### The thundering herd on TTL expiry

**Risk.** If 500 people abandon their reservations at 8:00, 500 TTLs expire in Redis at 8:10. Using keyspace notifications to trigger functions that update Postgres back to available creates a DDoS on our own database.

**Defence.** Instead of 500 individual triggers, run a reconciliation cron every minute executing one bulk query:

```sql
UPDATE slots SET status = 'AVAILABLE'
WHERE status = 'LOCKED' AND locked_at < NOW() - INTERVAL '10 minutes';
```

### Protected health information in Kafka

**Risk.** Kafka topics are just logs on disk. Storing patient intake forms there is a massive compliance vulnerability.

**Defence.** The application encrypts the `payload` JSON using envelope encryption with a KMS data key before it is written to `outbox_events`. Kafka only ever receives ciphertext, and the sync worker decrypts it right before sending it onward.

---

## The delayed dispatch pattern, which appears here too

A related question: if a campaign or reminder is scheduled for 9:00 AM, how do you hold millions of pending tasks for an hour?

**The batch size.** 5,000 is the production standard. Querying 5 million records at once crashes the database and the V8 memory limit, usually around 1.5 GB. Fetching 5,000 rows of just ID, name and phone creates a payload of roughly 1 to 2 MB, which is fast for the database to return, effortless to hold in RAM, and the perfect chunk to push into Kafka.

**What we store.** Not the final hydrated messages, because storing 5 million full strings wastes expensive cache memory. We store tasks, meaning instructions:

```json
{
  "task_id": "msg_999",
  "user_id": "u_123",
  "phone": "+123456789",
  "template_id": "promo_50",
  "execute_at": 1691254800
}
```

> [!warning] Redis is not a scheduler
> Redis has no internal cron jobs, cannot run scripts on a timer, and cannot trigger an API call. It is a very fast filing cabinet. Node.js is the scheduler, because it has the CPU, the `setInterval` timers and the HTTP clients.

So why Redis? Because if the worker pulls a task at 8:05 and sees it should not send until 9:00, it cannot hold 5 million tasks in local RAM for an hour without crashing. It needs a temporary parking lot, and that parking lot is a Redis sorted set.

**Step 1, parking at 8:00.** The dispatch worker pulls the task from Kafka, sees `execute_at` is in the future, and drops it into a sorted set scored by the Unix timestamp: `ZADD delayed_campaigns 1691254800 "{task_json}"`. It commits the Kafka offset and moves on. Kafka is now empty and Redis holds millions of perfectly time sorted tasks.

**Step 2, polling from 8:05 to 8:59.** A lightweight timer worker runs a `setInterval` every second, asking Redis `ZRANGEBYSCORE delayed_campaigns -inf <current_time>`. Redis returns an empty array and the worker sleeps again.

**Step 3, execution at 9:00:00.** The query now returns the tasks. Node.js pulls them out using `ZREMRANGEBYSCORE` to delete them from the parking lot, hydrates the final text, checks the Redis token bucket rate limiter so the downstream provider does not ban us, and fires the HTTP requests.

**The summary.** Kafka is the shock absorber that reliably transports the data. Redis is the perfectly sorted parking lot that holds it by timestamp. Node.js is the active engine that checks the parking lot every second and pulls the trigger.

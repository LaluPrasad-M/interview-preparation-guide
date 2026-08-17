# API Failures: Distributed Systems

> [!tldr]
> Failures across services and systems: transactions, file uploads, background jobs, ride assignment, blockchain, and the correctness toolbox.

Part of [[api-failure-scenarios]].

---

## 3. Order plus inventory, across services

Order, payment and inventory are independent services. The order is created, payment is charged, and inventory fails because the item is out of stock. Money is deducted with no inventory.

> [!warning] Why not a SQL transaction?
> The services are independent with no shared database, so ACID across them is not practical.

### Option 1: two phase commit

A coordinator asks everyone to prepare, then to commit. The problem is that if the coordinator crashes, participants stay locked. The system loses availability, which violates the usual preference for availability.

### The preferred option: saga

```text
Order     -> status PENDING
Payment   -> SUCCESS
Inventory -> FAIL
Compensation -> Refund payment
Order     -> FAILED
```

Each service executes a local transaction and publishes an event, and the next service reacts. On failure a compensating transaction is triggered. See [[distributed-transactions]].

### The interview question this sets up

**Why not just lock everything globally to avoid race conditions?**

Because application level locks do not work across multiple instances. Only database level locking guarantees correctness. Global locks kill scalability, and distributed locks add latency and complexity. Correctness must be enforced at the storage layer.

---

## 4. File upload to object storage plus Postgres

No orphaned files, no metadata pointing at a missing file, retry safe.

### The failure

The file uploads to S3 and the server crashes before the database insert. The object exists with no database record, which is an orphan.

The naive version has no transaction between S3 and the database, because S3 is an external system:

```js
await s3.upload(file)
await db.insert(metadata)
```

### The fix: two phase application logic

**Step 1, insert the database record first.**

```sql
INSERT INTO files (id, status) VALUES ('F1', 'INITIATED');
```

Commit that.

**Step 2, upload to S3.** On success, `UPDATE files SET status='UPLOADED'`.

**Step 3, a background cleanup worker.** If a file is stuck in `INITIATED` for long enough, delete the S3 object if it exists.

**Internally.** WAL keeps the metadata safe. S3 is eventually consistent object storage. There is no atomicity between them, so we use compensation.

---

## 5. Subscription renewal, a cron job

Every month, charge the user and create an invoice.

### The failure: the job runs twice

The cron restarts in a distributed system and the same user is processed twice, so they are charged twice. The naive loop has no guard.

### The fix: a unique constraint

```sql
CREATE UNIQUE INDEX unique_invoice
ON invoices(user_id, billing_cycle);
```

Then insert the invoice, and do nothing on a duplicate.

**Internally.** The B-tree index enforces uniqueness, the second insert fails atomically, and no race is possible.

**The principles.** Idempotent background processing, deterministic state transition, consistency by constraint.

---

## 6. Ride booking, driver assignment

A driver cannot be assigned to two rides.

### The failure

```sql
SELECT status FROM drivers WHERE id='D1';
-- status = AVAILABLE

UPDATE drivers SET status='ASSIGNED';
```

Two threads both read `AVAILABLE` and both assign.

### The fix: an atomic conditional update

```sql
UPDATE drivers
SET status='ASSIGNED'
WHERE id='D1' AND status='AVAILABLE';
```

Check the rows affected. One means success, zero means already taken.

**Internally.** Postgres acquires a row lock, re checks the condition at write time, and only one transaction succeeds.

**The principles.** Compare and set atomicity, row level locking, preventing the lost update anomaly.

---

## 7. Crypto withdrawal, async plus external plus blockchain

Blockchain confirmation may take minutes. No duplicate withdrawal, survive a crash, handle webhook retries, process asynchronously.

**Failure 1.** The user retries and a duplicate withdrawal is created. Fixed with a unique constraint on the idempotency key.

**Failure 2.** The blockchain confirms, the webhook arrives, and the server crashes before the database update. The chain completed but the database shows pending.

### The fix: the outbox pattern

```sql
BEGIN;

INSERT INTO withdrawals (..., status='PENDING');

INSERT INTO outbox_events (...);

COMMIT;
```

A worker reads the outbox table and publishes the blockchain request. The webhook handler then applies an idempotent update.

**Why it works.** The withdrawal row and the outbox row are written in the same transaction, so atomicity guarantees either both exist or neither does. No message loss.

**The principles.** Atomic message persistence, at least once event delivery, eventual consistency, a durable state machine.

---

## The correctness toolbox

Everything above draws from this set. Worth memorising as a table.

| Concept | Problem solved | Core idea | Typical syntax | Use case |
| --- | --- | --- | --- | --- |
| Pessimistic locking | two transactions modifying the same data | lock the row before modifying | `SELECT ... FOR UPDATE` | wallet transfer with simultaneous deductions |
| Optimistic locking | detect concurrent modification without locking upfront | version checking | `UPDATE ... WHERE id=1 AND version=3` | profile updates, low contention |
| Atomic conditional update | ensure only one transaction succeeds | update only if the condition still holds | `UPDATE drivers SET status='ASSIGNED' WHERE id='D1' AND status='AVAILABLE'` | ride booking |
| Transaction | all operations succeed or fail together | atomic commit and rollback | `BEGIN; ... COMMIT;` | debit one wallet, credit another |
| Rollback | undo incomplete changes | revert on failure | `ROLLBACK;` | failure mid transaction |
| Isolation level | control visibility between transactions | the DB controls read and write behaviour | `SET TRANSACTION ISOLATION LEVEL READ COMMITTED` | avoid dirty reads or lost updates |
| Idempotency key | prevent duplicate execution | the same request returns the same result | `CREATE UNIQUE INDEX ON payments(idempotency_key)` | payment retry after timeout |
| ON CONFLICT | safely ignore duplicate inserts | handle duplicates atomically | `INSERT ... ON CONFLICT(key) DO NOTHING` | retry safe APIs |
| Unique constraint | guarantee uniqueness at the DB layer | the DB prevents duplicates | `CREATE UNIQUE INDEX ON invoices(user_id, billing_cycle)` | monthly subscription billing |
| State machine | recover from a crash midway | persist the current state | `INSERT status='INITIATED'` then `UPDATE status='SUCCESS'` | gateway payment processing |
| Reconciliation worker | fix partial failures after restart | retry or check incomplete states | `SELECT * FROM payments WHERE status='INITIATED'` | gateway succeeded but the DB update failed |
| Write ahead log | durability after a crash | log before applying changes | internal DB mechanism | Postgres crash recovery |
| Saga | manage distributed transactions | compensate instead of rolling back | a business flow pattern | order, payment, inventory |
| Compensating transaction | undo a previous successful step | reverse the business action | refund payment, cancel order | inventory fails after payment success |
| Two phase commit | coordinate a commit across systems | prepare then commit | `PREPARE` then `COMMIT` | distributed DB transactions |
| Outbox | prevent DB and event inconsistency | save the event and the data in one transaction | `BEGIN; INSERT orders; INSERT outbox_events; COMMIT;` | Kafka event publishing |
| Eventual consistency | handle temporary inconsistency | the system becomes correct later | an architectural principle | refund issued later after inventory failure |
| Compare and set | prevent stale updates | update only if the expected value matches | `UPDATE inventory SET quantity = quantity - 1 WHERE product_id=1 AND quantity > 0` | stock reservation |
| Retry safe API | handle retries safely | idempotent processing | use an idempotency key | payment API |
| Background cleanup worker | remove orphaned resources | periodic cleanup | `SELECT * FROM files WHERE status='INITIATED'` | upload failed before the DB update |
| Choreography saga | distributed flow via events | services react independently | `OrderCreated -> PaymentProcessed` | event driven microservices |
| Orchestration saga | centralised distributed workflow | an orchestrator controls the steps | `Orchestrator -> Payment -> Inventory` | workflow engines |

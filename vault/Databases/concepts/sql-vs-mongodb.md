# Choosing Between SQL and MongoDB

> [!tldr]
> Both scale. The real question is where you want your complexity: in the database, or in the application.

---

## Stop thinking features, think invariants

Simplistic rules like "use Mongo for scale" and "use SQL for relationships" break down, because both modern SQL and MongoDB can scale, shard, replicate, index and handle large workloads.

So the decision is not about capability. It is about correctness guarantees, data shape, and where you want the complexity.

The real question is: what mistakes can your system absolutely not afford? Not how much data and not how low the latency, but can money be lost, can data be corrupted, can two users see inconsistent state, can updates conflict?

---

## The myth about scale

**Modern SQL** has read replicas, partitioning, sharding via Citus or Vitess, advanced indexing and horizontal scaling.

**Modern Mongo** has transactions since 4.0, sharding, replication and indexing.

Both scale. The real difference is how much work you push into the application layer.

> [!tip] The real trade off
> SQL means more constraints in the database and less logic in the application. Mongo means more freedom in the database and more responsibility in the application.

---

## Choose SQL when

**1. Strong consistency across multiple rows is critical.** Money transfers, inventory decrement, order plus payment plus ledger update, interview feedback plus status plus offer record. If multiple tables must update atomically, SQL wins by default.

**2. Data is relational.** Many to many relationships, deep joins, referential integrity, strong foreign key constraints. An applicant tracking system with candidate, interview, interviewer, feedback, offer and hiring team is naturally relational.

**3. You want constraints enforced by the database.** Foreign keys, unique constraints, ACID guarantees, serialisable isolation. That means less correctness logic in the application layer.

---

## Choose MongoDB when

**1. Data is naturally document oriented.** Self contained records with a natural JSON structure and preferred embedded objects.

```js
{
 order_id,
 user,
 restaurant,
 items: [
   { name, qty, price }
 ],
 delivery_status
}
```

That is a self contained document with no need for joins.

**2. Schema evolves rapidly.** Early stage startups, rapid feature iteration, constantly changing fields. Mongo avoids migration friction.

**3. Massive write throughput with relaxed relational constraints.** Logging events, tracking metrics, storing activity streams. Mongo or another NoSQL is often simpler.

---

## What SQL gives you out of the box

Four things by default, which together solve concurrency without you writing locking code.

### 1. Transactions, the foundation

```sql
BEGIN
  UPDATE cart_items ...;
  UPDATE carts SET version = ...;
COMMIT
```

You are telling the DB to treat this as one indivisible unit. If anything fails the DB rolls back and no partial state ever exists. You do not write rollback logic, the DB does it.

### 2. Row level locking

When SQL executes:

```sql
UPDATE carts
SET version = version + 1
WHERE cart_id = 'c1' AND version = 5;
```

The database locates the row, places a lock on it, performs the update, then releases the lock. Only one transaction can modify that row at a time. This is automatic. You did not ask for it or configure it.

**The timeline with two concurrent requests.** Both arrive with `WHERE version = 5`. One acquires the row lock first and updates version to 6, then releases. The second now runs, `WHERE version = 5` fails, and rows affected is 0.

No lost update, no corruption, no race condition. You did not write a mutex. The DB enforced correctness.

### 3. MVCC, why reads do not block writes

Readers see a snapshot. Writers do not block readers, and readers do not block writers. So `GET /cart` is fast, concurrent writes are safe, and there is no global locking.

**Isolation levels under MVCC.**

| Level | Behaviour |
| --- | --- |
| Read committed | snapshot taken per statement, each `SELECT` sees the latest committed data at statement start |
| Repeatable read | snapshot taken at transaction start, the same data visible throughout |
| Serialisable | the database detects conflicts and may throw serialisation errors, so the application must retry |

**Read plus write.** No blocking. The reader sees the last committed version and the writer creates a new version.

**Write plus write on the same row.** A row level lock, so the second writer waits, or gets a serialisation error at stricter levels. Writes are always serialised.

### 4. Constraints, database level validation

```sql
UNIQUE (cart_id, product_id)
```

Two concurrent inserts of the same product: one succeeds, one fails. No application logic and no race window, because the DB enforces the invariant.

**Why this feels automatic in SQL.** SQL was designed for shared mutable state. Concurrency is not an afterthought, it is the core problem SQL was built to solve.

---

## Compare with Mongo

By default Mongo gives single document atomicity only, no row level locking across documents, no built in optimistic locking, and weaker constraints.

So if cart and cart items live in different documents, you must manage consistency yourself, write retry logic, and detect conflicts manually.

Mongo can do transactions now, but with higher overhead, more complexity, and not naturally the way SQL is. That is why people say Mongo requires more care for concurrent state updates.

> [!tip] The interviewer level explanation
> Relational databases handle concurrency using transactions, row level locking, and MVCC. When we use optimistic locking with a version column, the database ensures that only one concurrent update succeeds, while others safely fail and retry. This avoids explicit distributed locks and keeps cart updates correct.

**The final mental model.** SQL does not remove concurrency problems, it constrains the ways concurrency can go wrong. Mongo gives flexibility, SQL gives safety.

---

## When the NFRs decide

| Question | Leans |
| --- | --- |
| Can temporary inconsistencies exist? Can double booking happen? Can stale reads break business logic? | strong consistency needed means SQL |
| Can you retry operations safely? Are eventual consistency delays acceptable? | yes means NoSQL is viable |
| Many joins, ad hoc reporting, analytics? | SQL is much stronger |
| Stable domain model, or evolving JSON like objects? | stable means SQL, evolving means Mongo |
| Team expertise | underrated. Operational simplicity matters more than theoretical benefits |

---

## The strong conviction framework

Instead of asking "which database can handle it?", ask:

1. What invariants must never break?
2. Where do I want my complexity, in the DB or in the application?
3. What failure mode am I willing to tolerate?
4. Will reporting and analytics be heavy?
5. How often will the schema evolve?

---

## The mature perspective

For most business systems, start with SQL unless you have a strong reason not to. It is safer, it enforces structure, it reduces hidden bugs, and it handles relational domains better.

Mongo is excellent when data is document centric, scale out is the primary concern, the domain is loosely structured, or the workload is event and log heavy.

---

## Two worked comparisons

**Food delivery.** Core operations are place order, deduct inventory, charge payment, update delivery status. If inventory must never go negative, payments must match orders exactly, and refund logic is complex, SQL gives safer transactional boundaries. Mongo works too, but you write more correctness logic.

**Applicant tracking system.** Candidate, interview round, panel feedback, hiring decision, offer. These are relational, needing joins, aggregations, filters across relationships, and consistent status transitions. A relational DB is naturally aligned. Mongo would work, but you would denormalise heavily.

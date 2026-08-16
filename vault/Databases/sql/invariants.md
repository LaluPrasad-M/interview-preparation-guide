# Database Invariants

> [!tldr]
> Real database design is not creating tables. It is preventing invalid business states. An invariant is a condition that must always remain true.

---

## The mindset

Strong backend engineers constantly ask two questions in order.

1. What invalid state must never happen?
2. How do I enforce that using database guarantees?

Then a third: does this belong in the database layer, the service layer, or both?

---

## The types

| Type | Example |
| --- | --- |
| Structural | the user must exist |
| Relational | a delivery must reference a valid order |
| Uniqueness | a duplicate payment is not allowed |
| Transactional | order and items must commit together |
| Concurrency | inventory cannot go negative |
| Historical | old orders must preserve old prices |
| Workflow | invalid status transitions are forbidden |
| Derived data | `total_amount` must match the items |

---

## 1. Entity existence

**Invariant.** An order must belong to an existing user.

**Invalid state.** `orders.user_id = 999` with no such user.

```sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,

    FOREIGN KEY (user_id)
    REFERENCES users(id)
);
```

The database prevents orphan records and invalid references. The mental model is referential integrity.

---

## 2. Uniqueness

**Invariant.** An email must be unique, or an idempotency key must be unique.

```sql
email VARCHAR(255) UNIQUE

idempotency_key VARCHAR(255) UNIQUE
```

The database rejects duplicates automatically. The mental model is database assisted idempotency, which is a very important backend concept. See [[idempotency]].

---

## 3. Non null

**Invariant.** Critical fields must always exist: order ID, payment amount, user email.

```sql
amount DECIMAL(10,2) NOT NULL
```

Prevents partially invalid rows.

---

## 4. Domain value

**Invariant.** Order status must be one of the allowed values.

```sql
CHECK (
    status IN (
        'PENDING',
        'PAID',
        'CANCELLED'
    )
)
```

> [!warning] The limitation
> `CHECK` handles structural validity, not workflow or state machine logic.

---

## 5. Transactional

**Invariant.** Order and order items must commit together.

**Invalid state.** The order is inserted, the items fail, and you have an empty order.

```sql
BEGIN;

INSERT INTO orders (...);

INSERT INTO order_items (...);

COMMIT;
```

Atomicity: everything succeeds, or nothing persists.

---

## 6. Concurrency

**Invariant.** Inventory cannot become negative.

**Invalid state.** Two users buy the last item simultaneously and quantity becomes -1.

```sql
BEGIN;

SELECT quantity
FROM inventory
WHERE item_id = 1
FOR UPDATE;

UPDATE inventory
SET quantity = quantity - 1
WHERE item_id = 1;

COMMIT;
```

Isolation plus locking prevents the race. See [[locking-strategies]] for when an atomic update beats this.

---

## 7. Historical consistency

**Invariant.** Old orders must preserve old prices.

**Invalid state.** A product price changes from 200 to 300 and old orders suddenly show 300. That is historical corruption.

**The solution.** Snapshotting, which is intentional denormalisation.

```sql
order_items (
    order_id,
    item_name,
    item_price
)
```

The principle is immutable historical snapshots.

---

## 8. Derived data

**Invariant.** The order total must equal the sum of its items.

```sql
BEGIN;

INSERT INTO order_items (...);

UPDATE orders
SET total_amount = (
    SELECT SUM(quantity * item_price)
    FROM order_items
    WHERE order_id = ?
);

COMMIT;
```

---

## 9. Workflow

**Invariant.** Invalid status transitions are forbidden, for example `PENDING` straight to `DELIVERED` without `CONFIRMED` and `PICKED_UP`.

This is a business workflow invariant, usually enforced in the service layer or domain logic. SQL can help partially with `CHECK(status IN (...))`, but is usually insufficient for state machine transitions.

> [!tip] The distinction worth stating
> Structural invariants fit database constraints well. Workflow invariants usually belong in the application or service layer.

---

## 10. Deletion

**Invariant.** Historical records should remain recoverable.

A hard delete can break audits, analytics and history. Use a soft delete instead.

```sql
deleted_at TIMESTAMP NULL
```

The principle is logical deletion rather than physical deletion.

---

## 11. Cross table business rules

**Invariant.** A payment amount cannot exceed the order amount.

This needs cross table validation, which is harder than a simple `CHECK`. Usually enforced in the application layer inside a transaction. Triggers and stored procedures are possible, but heavy trigger logic becomes hard to maintain.

> [!tip] The senior answer
> I prefer core structural invariants in database constraints, and more complex business workflow invariants in service layer transaction boundaries.

---

## The toolbox

**Structural integrity.**

| Tool | Purpose |
| --- | --- |
| `PRIMARY KEY` | row identity |
| `FOREIGN KEY` | referential integrity |
| `UNIQUE` | uniqueness |
| `NOT NULL` | mandatory fields |
| `CHECK` | valid value range |

**Transactional integrity.** `BEGIN` starts, `COMMIT` persists atomically, `ROLLBACK` reverts on failure.

**Concurrency control.** `FOR UPDATE` for a row lock, isolation levels for concurrent correctness, locks for race prevention.

**Historical consistency.** Snapshotting to preserve history, denormalisation for immutable transactional state.

**Idempotency.** A `UNIQUE` constraint for retry safety.

---

## The phrases worth using

Preserving business invariants. Preventing invalid state transitions. Enforcing referential integrity. Maintaining transactional consistency. Using snapshotting for historical correctness. Using unique constraints for idempotency. Using row level locking to prevent race conditions. Separating structural invariants from workflow invariants.

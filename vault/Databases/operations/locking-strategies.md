# Optimistic, Pessimistic and Atomic Updates

> [!tldr]
> These are not three competing solutions to one problem. They are three different categories, and atomic updates are the one people forget.

---

## The problem all three solve

Stock is 5 and two users buy simultaneously. User A reads 5, user B reads 5, both write 4. The final stock is 4 instead of 3.

That is the lost update problem. All three techniques can solve it.

---

## 1. Pessimistic locking

**The mental model.** Assume conflicts will happen.

```sql
BEGIN;

SELECT *
FROM inventory
WHERE id = 1
FOR UPDATE;
```

The row is now locked, so a second transaction issuing the same statement must wait.

```text
T1 acquires lock
      |
      |  updates stock
      |
      |  commits
      |
T2 acquires lock
```

**Pros.** Simple reasoning, very strong consistency, no retries needed.

**Cons.** Lock contention, reduced throughput, deadlock possibility.

**Best for.** Payments, wallets, banking, ticket booking, where correctness dominates throughput.

---

## 2. Optimistic locking

**The mental model.** Assume conflicts are rare. No lock is taken.

The table carries a `version` column. Current state is `stock = 5`, `version = 10`. Both users read that.

```sql
UPDATE inventory
SET stock = 4,
    version = 11
WHERE id = 1
AND version = 10;
```

User A succeeds. User B runs the identical statement and gets zero rows affected, because the version already changed. The conflict is detected.

**Pros.** No lock contention, higher throughput, scales well.

**Cons.** Retries are required, and conflicts waste work.

**Best for.** Profile updates, product catalogs, settings, documents, where collisions are uncommon.

---

## 3. Atomic updates

This is the one people misunderstand.

**The mental model.** I do not care about the current value. Just apply a mathematical operation atomically.

Instead of read, modify, write from the application:

```sql
UPDATE inventory
SET stock = stock - 1
WHERE id = 1;
```

The database reads the current value, applies the change and writes the new value as one atomic operation. There is no application side read.

**Why it works.** With ten concurrent decrements the database serialises the row updates internally, so the values step down cleanly with no lost updates.

> [!warning] What atomic updates do not solve
> They fix the lost update problem, but not business rule validation. The statement above will happily take stock to `-1`.
>
> ```sql
> UPDATE inventory
> SET stock = stock - 1
> WHERE stock > 0;
> ```
>
> Now rows affected of 1 means success and 0 means out of stock. That is a very important interview pattern.

**The hidden insight.** An atomic update is neither optimistic nor pessimistic. It is a different category, because from the application's perspective there is no explicit lock and no version column. The database handles concurrency internally.

---

## The same inventory decrement, three ways

```sql
-- Pessimistic
SELECT stock FOR UPDATE;
-- then, in application code: if (stock > 0) stock--;
UPDATE inventory SET stock = ...;
```

```sql
-- Optimistic
UPDATE inventory
SET stock = stock - 1,
    version = version + 1
WHERE version = ?;
```

```sql
-- Atomic, a single statement
UPDATE inventory
SET stock = stock - 1
WHERE stock > 0;
```

---

## The comparison

| Aspect | Atomic update | Optimistic locking | Pessimistic locking |
| --- | --- | --- | --- |
| Explicit lock | no | no | yes |
| Version column | no | yes | no |
| Conflict detection | implicit | explicit | prevented |
| Retries needed | no | yes | no |
| Throughput | highest | high | lowest |
| Contention handling | the DB serialises the operation | retry on conflict | wait on the lock |
| Lost update prevention | yes | yes | yes |
| Deadlocks possible | rare | no | yes |
| Typical use | counters, inventory decrement | user edits | banking, payments |

---

## Which one, three worked questions

**Like count, view count, download count.** Atomic update. You need an increment, you do not care who incremented, and you need neither versioning nor locking.

**Bank transfer.** Pessimistic locking, or sometimes a serialisable transaction, because money cannot disappear.

**A user editing their profile with two browser tabs open.** Optimistic locking, using `version`, `updated_at` or an etag, because conflicts are rare and the user can retry.

---

## The most important insight

The common mistake is assuming inventory means optimistic locking. Not necessarily.

If the operation is simply decrement stock by one, then `UPDATE inventory SET stock = stock - 1 WHERE stock > 0` is often superior to both, because you are expressing the business operation directly to the database instead of doing read, modify, write in the application.

> [!tip] The mental model to keep
> Whenever the operation can be expressed as a single atomic SQL statement, prefer that over pulling data into the application and introducing a concurrency problem the database already knows how to solve.

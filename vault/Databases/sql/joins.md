# Joins and Their Traps

> [!tldr]
> Every join bug in an interview is one of three things: fan out inflating your sums, a `WHERE` clause silently turning a `LEFT JOIN` into an `INNER JOIN`, or `NOT IN` meeting a `NULL`.

---

## The standard schema

### `users`

| id | name | city |
| --- | --- | --- |
| 1 | Rahul | Bangalore |
| 2 | Aman | Delhi |
| 3 | Neha | Mumbai |

### `orders`

| id | user_id | amount | status | created_at |
| --- | --- | --- | --- | --- |
| 1 | 1 | 100 | PAID | 2026-01-01 |
| 2 | 1 | 200 | PAID | 2026-01-02 |
| 3 | 2 | 50 | FAILED | 2026-01-03 |
| 4 | 1 | 300 | SHIPPED | 2026-01-04 |

---

## Inner join, the intersection

**Get all users with their orders.**

Mental model: `INNER JOIN` is the intersection. It only returns rows that exist in both tables.

```sql
SELECT u.name, o.amount
FROM users u
INNER JOIN orders o
  ON u.id = o.user_id;
```

> [!warning] One to many expansion
> If a user has multiple orders, the rows multiply. Rahul appears 3 times because 1 user row matched 3 order rows. Avoid the old syntax `FROM users u, orders o WHERE ...` in interviews. Explicit `JOIN` syntax is preferred.

### The cartesian explosion trap

**Follow up.** "Calculate total user spending and total user logins in one query."

**The trap.** If you join `users` to `orders` and then to `logins`, which also has multiple rows per user, the data fans out geometrically. Summing amounts on fanned out data creates massively inflated numbers.

**The fix.** Aggregate the data inside isolated CTEs before joining them back to the main `users` table.

---

## Left join, keep the left

**Show all users even if they never placed orders.**

```sql
SELECT u.name, o.amount
FROM users u
LEFT JOIN orders o
  ON u.id = o.user_id;
```

### The accidental inner join trap

**The trap.** You filter a `LEFT JOIN` in the `WHERE` clause with `WHERE o.amount > 100`.

**The reality.** `WHERE` removes `NULL` rows. Users with no orders have `NULL` amounts, so they are immediately filtered out, turning it into an `INNER JOIN`.

**The fix.** Move the condition to the `ON` clause: `ON u.id = o.user_id AND o.amount > 100`.

### The two cases side by side

**Case 1, payment report.** "Show users who paid successfully." Only paying users matter, so an inner join with `WHERE p.status = 'SUCCESS'` is perfectly correct.

```sql
SELECT *
FROM users u
INNER JOIN payments p
  ON u.id = p.user_id
WHERE p.status = 'SUCCESS';
```

**Case 2, admin dashboard.** "Show all users and whether they paid." Now unmatched users matter, because the product team wants active users, unpaid users, the conversion funnel, free against paid. So the filter belongs in `ON`.

```sql
SELECT *
FROM users u
LEFT JOIN payments p
  ON u.id = p.user_id
  AND p.status = 'SUCCESS';
```

Now users without payments still appear.

---

## Right join

Same as `LEFT JOIN`, reversed.

---

## Finding missing data, the unmatched

**Find users who never placed orders.**

Mental model: `LEFT JOIN` creates `NULL`s for unmatched rows, so filter those `NULL`s.

```sql
SELECT u.*
FROM users u
LEFT JOIN orders o
  ON u.id = o.user_id
WHERE o.id IS NULL;
```

> [!warning] Check the right table
> Always check `WHERE right_table.id IS NULL`. Never check `left_table.id IS NULL`.

### The three valued logic black hole

**The trap.** Using `WHERE user_id NOT IN (SELECT user_id FROM orders)`.

**The reality.** If the subquery returns even one `NULL`, the entire `NOT IN` condition evaluates to `UNKNOWN`, effectively `FALSE`, and your query returns zero rows.

**The fix.** `NOT EXISTS` is preferred at scale, because it stops early after finding a match and is immune to the `NULL` trap.

---

## `EXISTS` against `IN`

**`IN`** builds the full list first, which is slower for large data.

**`EXISTS`** stops on the first match, which is more efficient.

```sql
SELECT * FROM users u
WHERE EXISTS (
  SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

Rule: prefer `EXISTS` for large datasets.

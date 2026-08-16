# Query Patterns and Traps

> [!tldr]
> The recurring interview shapes: bucket and filter, dedupe, hierarchy, categorise, and date filtering that does not destroy your index.

---

## Group by and having

**Find users whose total spending is above 250.**

Mental model: `GROUP BY` creates buckets and aggregates inside them. `WHERE` filters rows before grouping. `HAVING` filters groups after aggregation.

```sql
SELECT user_id, SUM(amount) AS total
FROM orders
GROUP BY user_id
HAVING SUM(amount) > 250;
```

> [!warning] Two gotchas
> You cannot put an unaggregated column in `SELECT` unless it is in `GROUP BY`. And you cannot write `WHERE SUM(amount) > 250`, because `WHERE` runs before grouping.

So this errors:

```sql
SELECT user_id, amount
FROM orders
GROUP BY user_id;
```

`amount` is neither aggregated nor in the `GROUP BY`.

### The division by zero and COUNT illusion

**The trap.** Calculating averages as `SUM(amount) / COUNT(order_id)`.

**The reality.** `COUNT(*)` counts all rows including `NULL`s. `COUNT(column)` counts only non null values. If a user has 0 orders, dividing by 0 crashes the query.

**The fix.** Use `NULLIF`: `SUM(amount) * 1.0 / NULLIF(COUNT(order_id), 0)`.

---

## Duplicates

**Find duplicate emails.**

```sql
SELECT email, COUNT(*) AS cnt
FROM employees
GROUP BY email
HAVING COUNT(*) > 1;
```

**Delete duplicates, keeping the latest.** Use a CTE with `ROW_NUMBER()` to assign ranks, then delete anything ranked above 1.

```sql
WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY email
            ORDER BY created_at DESC, id DESC
        ) AS rn
    FROM employees
)
DELETE FROM employees
WHERE id IN (
    SELECT id
    FROM ranked
    WHERE rn > 1
);
```

---

## CTEs

**Get users whose spending is above the average spending.**

```sql
SELECT *
FROM (
    SELECT
        id,
        email,
        spending,
        AVG(spending) OVER () AS avg_spending
    FROM users
) t
WHERE spending > avg_spending;
```

> [!warning] CTEs are not a performance tool
> They are temporary named results that improve readability, but they do not always improve performance. Some databases materialise them, others inline them.

---

## Recursive CTE for hierarchies

**Find all employees reporting to a manager.**

```sql
WITH RECURSIVE EmployeeHierarchy AS (
   SELECT employee_id, name, manager_id
   FROM Employee
   WHERE employee_id = 1
   UNION ALL
   SELECT e.employee_id, e.name, e.manager_id
   FROM Employee e
   JOIN EmployeeHierarchy h
       ON e.manager_id = h.employee_id
)
SELECT * FROM EmployeeHierarchy;
```

---

## Choosing a hierarchy model

The recursive CTE above assumes the adjacency list model. That is one of four ways to store a tree.

### The adjacency list

Each row stores a reference to its parent in the same table.

```sql
CREATE TABLE categories (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  parent_id INT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
);
```

| id | name | parent_id |
| --- | --- | --- |
| 1 | Electronics | NULL |
| 2 | Laptops | 1 |
| 3 | Phones | 1 |
| 4 | Gaming | 2 |

```text
Electronics
|-- Laptops
|     +-- Gaming
+-- Phones
```

A root has `parent_id` NULL, a child points at its parent's id, and siblings share a `parent_id`.

**Advantages.** Very simple, easy to insert and delete nodes, natural relational modelling, minimal storage overhead.

**Disadvantages.** Recursive queries are required, deep trees get slower on large hierarchies, whole subtrees are harder to query efficiently, and depth is not stored directly.

> [!warning] Why `WHERE parent_id = 3` is not enough
> That returns only the direct reports. Anything further down the tree needs the recursive CTE.

### The four models compared

| Model | Best for | Complexity |
| --- | --- | --- |
| Adjacency list | simple trees, frequent writes | low |
| Nested set | read heavy trees, whole subtree queries | high |
| Materialized path | path based lookup and sorting | medium |
| Closure table | arbitrary ancestor and descendant queries | medium to high, extra table |

---

## Categorisation with CASE WHEN

```sql
SELECT amount,
   CASE
       WHEN amount >= 200 THEN 'HIGH'
       WHEN amount >= 100 THEN 'MEDIUM'
       ELSE 'LOW'
   END AS category
FROM orders;
```

Use cases: conditional aggregation, categorisation, pivoting data.

---

## The sargability trap

**Get orders created in a specific year, or the last 24 hours.**

**The trap.** You write `WHERE YEAR(created_at) = 2026`.

**The reality.** Applying a function to an indexed column in `WHERE` makes the query non sargable. The database must do a full table scan and compute the function on every row before filtering.

**The fix.** Use explicit boundaries so the database can do an index seek:

```sql
WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'
```

Avoid `BETWEEN`, because it includes midnight of the end date.

For "last 24 hours", the syntax varies. Postgres uses `NOW() - INTERVAL '1 DAY'`, MySQL uses `NOW() - INTERVAL 1 DAY`.

---

## Rapid fire cheat sheet

| Instantly think of | Pattern to use |
| --- | --- |
| Matching rows | `INNER JOIN` |
| Keep left side | `LEFT JOIN` |
| Missing rows | `LEFT JOIN` plus `IS NULL`, or `NOT EXISTS` |
| Bucket then aggregate | `GROUP BY` |
| Filter aggregated result | `HAVING` |
| Latest row per group | `ROW_NUMBER()` |
| Top N per group | `ROW_NUMBER()` or `DENSE_RANK()` |
| Ties with gaps | `RANK()` |
| Ties without gaps | `DENSE_RANK()` |
| Running analytics | `SUM() OVER (...)` |
| Previous row | `LAG()` |
| Duplicates | `GROUP BY` plus `HAVING COUNT(*) > 1` |

---

## The ultra short summary

`JOIN` builds data. `WHERE` filters rows. `GROUP BY` buckets. `HAVING` filters groups. Window functions compute without collapsing. `ROW_NUMBER` gives exact rank, `LAG` gives the previous row, `FIRST_VALUE` gives the first row. Always think in [[execution-order]].

# SQL Execution Order

> [!tldr]
> Read queries the way the planner executes them, not the way you wrote them. Memorise this order and you never fall for a syntax trick again.

---

## The order

| Step | Clause | What it does |
| --- | --- | --- |
| 1 | `FROM` | chooses the base tables |
| 2 | `JOIN` | merges more tables in |
| 3 | `WHERE` | filters individual rows |
| 4 | `GROUP BY` | rolls rows up into buckets |
| 5 | Aggregate functions | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` |
| 6 | `HAVING` | filters the grouped buckets |
| 7 | Window functions | analytics without collapsing rows |
| 8 | `SELECT` | computes the final expressions and aliases |
| 9 | `DISTINCT` | removes duplicate final rows |
| 10 | `ORDER BY` | sorts the final output |
| 11 | `LIMIT` / `OFFSET` | returns a subset of the sorted rows |

> [!tip] Memory trick
> "Funny Joiners Wear Green Hats Singing Old Lyrics."

---

## The mental story

**1. `FROM`.** Where is the data coming from? Start with the base table.

```sql
FROM employees
```

**2. `JOIN`.** Attach more data. At this point you have one large intermediate table.

```sql
JOIN departments d ON e.department_id = d.id
```

**3. `WHERE`.** Throw away unwanted rows, before grouping.

```sql
WHERE salary > 50000
```

Window functions are not allowed here, and neither are aggregates, because grouping and windowing have not happened yet.

**4. `GROUP BY`.** Create buckets. Collapse rows into groups.

```sql
GROUP BY department
```

Conceptually:

```text
Engineering:
  row1
  row2

HR:
  row3
  row4
```

**5. `HAVING`.** Throw away unwanted buckets, after aggregation. Aggregates are legal here because groups now exist.

```sql
HAVING COUNT(*) > 5
```

**6. Window functions.** Do analytics over the result without collapsing rows. This is the mental layer most people never visualise properly.

They happen after grouping, after `HAVING`, and before the final `SELECT` output. Examples are `ROW_NUMBER()`, `RANK()`, `SUM() OVER()`, `AVG() OVER()`, `LAG()` and `LEAD()`.

**7. `SELECT`.** Now decide what to show: aliases, computed columns, the final projection. Aliases become usable after this stage.

**8. `DISTINCT`.** Remove duplicate final rows.

**9. `ORDER BY`.** Sort the final result. Aliases work here, because they already exist.

```sql
ORDER BY total DESC
```

**10. `LIMIT`.** The final trimming step.

---

## The very important distinction

### `GROUP BY` collapses rows

```sql
SELECT user_id, SUM(amount)
FROM orders
GROUP BY user_id;
```

| user_id | total |
| --- | --- |
| 1 | 500 |
| 2 | 900 |

### A window function preserves rows

```sql
SELECT
  user_id,
  amount,
  SUM(amount) OVER (PARTITION BY user_id)
FROM orders;
```

| user_id | amount | total |
| --- | --- | --- |
| 1 | 100 | 500 |
| 1 | 400 | 500 |

---

## Why window functions run after `GROUP BY`

Because they can operate on raw rows, or on grouped and aggregated results.

```sql
SELECT
  department,
  COUNT(*) AS total_employees,
  RANK() OVER (ORDER BY COUNT(*) DESC)
FROM employees
GROUP BY department;
```

The flow is: employees, group by department, count employees, then rank those grouped rows. This is a very important detail.

---

## The interview thinking rules

| Rule | The question | The answer |
| --- | --- | --- |
| 1 | What is the grouping dimension? | use it in `PARTITION BY` or `GROUP BY` |
| 2 | Do I want to collapse rows? | yes means `GROUP BY`, no means a window function |
| 3 | Am I filtering rows or groups? | rows means `WHERE`, groups means `HAVING` |
| 4 | Do I need position or value? | position means `ROW_NUMBER`, value means `LAG` or `FIRST_VALUE` |

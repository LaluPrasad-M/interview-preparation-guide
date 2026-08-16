# Window Functions

> [!tldr]
> Window functions compute aggregations without collapsing rows. `GROUP BY` collapses rows, window functions preserve them.

---

## The syntax

```sql
OVER (
  PARTITION BY ...
  ORDER BY ...
)
```

**`PARTITION BY`** is like `GROUP BY`, but it keeps the rows.

**`ORDER BY`** defines the sequence inside the partition.

---

## The rank family

If scores are 100, 100, 90:

| Function | Behaviour | Ranks |
| --- | --- | --- |
| `ROW_NUMBER()` | every row gets a unique number, no shared rank and no gaps | 1, 2, 3 |
| `RANK()` | Olympic ranking, shares ranks and leaves gaps after ties | 1, 1, 3 |
| `DENSE_RANK()` | compressed ranking, shares ranks with no gaps | 1, 1, 2 |

**The rule.** Exact nth row means `ROW_NUMBER`. Ranking with ties means `RANK`. Ranking without gaps means `DENSE_RANK`.

> [!tip] Staff tip
> For "nth highest salary" problems, `DENSE_RANK()` handles duplicates naturally and is much better than nested subqueries.

---

## Latest row per group

**Find the latest order per user.**

Mental model: `PARTITION BY` is logical grouping, `ORDER BY` is ranking sequence, `ROW_NUMBER` is exact position.

```sql
SELECT *
FROM (
  SELECT *, ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY created_at DESC
  ) AS rn
  FROM orders
) t
WHERE rn = 1;
```

> [!warning] Non deterministic sorting
> If timestamps tie, `ROW_NUMBER` becomes non deterministic. The follow up is "how do you guarantee deterministic output for exactly the same scores?" The fix is a tie breaker: `ORDER BY created_at DESC, id DESC`.

---

## Top N per group

**Get the top 2 highest orders per user.**

```sql
WITH RankedOrders AS (
   SELECT *, ROW_NUMBER() OVER (
       PARTITION BY user_id ORDER BY amount DESC
   ) AS rn
   FROM orders
)
SELECT * FROM RankedOrders WHERE rn <= 2;
```

> [!warning] You cannot filter a window function in `WHERE`
> `WHERE ROW_NUMBER() <= 2` is illegal, because `WHERE` runs before window functions. A subquery or CTE is strictly required.

---

## Running totals and previous rows

**Show current amount, previous amount, and the difference.**

```sql
SELECT *, amount - prev_amount AS difference
FROM (
  SELECT amount,
         LAG(amount) OVER (PARTITION BY user_id ORDER BY created_at) AS prev_amount
  FROM orders
) t;
```

> [!warning] The first row NULL
> The first row has no previous row, so `LAG` returns `NULL`, and maths with `NULL` yields `NULL`. Wrap it: `COALESCE(LAG(amount) OVER (...), 0)`.

---

## The pattern catalogue

**Latest or nth row.**

```sql
ROW_NUMBER() OVER (
  PARTITION BY user_id
  ORDER BY created_at DESC
)
```

**Running total.**

```sql
SUM(amount) OVER (
  PARTITION BY user_id
  ORDER BY created_at
)
```

**Previous value.** `LAG(amount) OVER (...)`

**Next value.** `LEAD(amount) OVER (...)`

**First value.** `FIRST_VALUE(amount) OVER (...)`

**Pivot using CASE.** `MAX(CASE WHEN rn = 1 THEN amount END)`

> [!tip] Key insight
> Window functions behave like columns. You can write `amount - LAG(amount)`.

---

## Edge cases

**Cannot use a window function in `WHERE`.** Use a subquery.

**Duplicate timestamps.** Add a tie breaker: `ORDER BY created_at DESC, id DESC`.

**NULL behaviour.** `NULL` in a comparison is false, and `LAG()` on the first row returns `NULL`.

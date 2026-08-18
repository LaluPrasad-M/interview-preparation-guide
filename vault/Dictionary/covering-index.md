# Covering Index

> [!tldr]
> An index that already holds every column a query asks for, so the database answers from the index alone and never goes back to fetch the row.

Normally an index is a lookup table that ends in a pointer. The database walks the index to find which rows match, then follows each pointer to the actual row to read the columns you selected. That second step is the expensive part, because those rows are scattered across the disk.

> [!example]- One query, one extra column in the index
>
> ```sql
> SELECT status, total FROM orders WHERE userId = 42;
> ```
>
> | Index you built | What the database does |
> | --- | --- |
> | `(userId)` | finds 300 matching entries, then does 300 random row fetches to read `status` and `total` |
> | `(userId, status, total)` | reads all 300 answers straight out of the index and stops |
>
> The second one is a covering index for this query. Postgres calls the result an index only scan; MongoDB calls it a covered query.

The rule is simple: the index covers the query when every column in the `SELECT`, the `WHERE` and the `ORDER BY` is somewhere in the index.

> [!warning] The cost lands on writes
> A wider index is a bigger index, and every insert or update now has to maintain those extra columns too. Covering a rare report query with a five column index is usually a bad trade; covering your busiest read path is usually a good one.

In MongoDB there is one extra catch: `_id` comes back by default and is rarely in your index, so a query is only covered if you explicitly project it away with `{ _id: 0 }`.

**Shows up in:** [[query-optimization]], [[indexing]], [[study-roadmap]].

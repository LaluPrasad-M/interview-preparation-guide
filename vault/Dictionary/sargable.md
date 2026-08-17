# Sargable

> [!tldr]
> A `WHERE` clause the database can answer with an index seek, because it never wraps the indexed column in a function.

`WHERE created_at >= '2026-01-01'` is sargable. `WHERE YEAR(created_at) = 2026` is not, because the database must compute `YEAR()` on every row before it can filter, forcing a full table scan even with an index in place.

The fix is always the same: rewrite the condition as an explicit range on the raw column.

**Shows up in:** [[query-patterns]].

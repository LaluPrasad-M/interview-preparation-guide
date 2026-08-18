# Sargable (Search ARGument ABLE)

> [!tldr]
> A `WHERE` clause the database can answer by seeking straight into an index. It stays sargable as long as the indexed column is left alone on its side of the comparison.

An index is sorted by the raw column value. The moment you wrap that column in a function, the sorted order no longer matches what you are comparing, so the database has to compute the function for every row before it can decide anything. Your index sits there unused.

| Not sargable | Sargable rewrite | Why |
| --- | --- | --- |
| `WHERE YEAR(created_at) = 2026` | `WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'` | the index is sorted by `created_at`, not by its year |
| `WHERE LOWER(email) = 'a@b.com'` | store it lowercased, or index `LOWER(email)` | same problem, one function call per row |
| `WHERE name LIKE '%smith'` | `LIKE 'smith%'` | an index can seek a known prefix, not a known ending |
| `WHERE price * 1.18 > 500` | `WHERE price > 423.73` | move the arithmetic to the constant side |
| `WHERE CAST(id AS TEXT) = '42'` | `WHERE id = 42` | an implicit type change is still a function |

The difference at scale is total, not marginal. On 10 million rows the sargable version touches a few hundred index entries, and the other one reads all 10 million rows to throw nearly all of them away.

> [!tip] The rule fits in one line
> Keep the column bare on the left, do the work on the right. If you cannot, an index on the expression itself is the fallback, at the usual cost of a wider index and slower writes.

**Shows up in:** [[query-patterns]].

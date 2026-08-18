# Multi-Version Concurrency Control (MVCC)

> [!tldr]
> The database keeps several versions of each row, and every transaction reads the version that was current when it started. That is why readers never block writers and writers never block readers.

The alternative is locking: a writer takes the row, and readers queue behind it. MVCC avoids the queue by never overwriting in place. An update writes a new version and marks the old one as valid up to that point, so a reader that started earlier can still see the old one.

> [!example]- Two transactions, one row
>
> ```text
> 10:00:00  transaction A begins, reads balance = 100
> 10:00:01  transaction B updates balance to 50 and commits
> 10:00:02  transaction A reads balance again  -> still 100
> ```
> A is not stale by accident. It was promised a consistent snapshot from the moment it began, and it gets that for its whole life. B never had to wait for A, and A never had to wait for B.

| | Lock based reads | MVCC |
| --- | --- | --- |
| Reader meets a writer | reader waits | reader sees the older version |
| Writer meets a reader | writer waits | writer proceeds |
| A long analytics query | blocks writes for its whole run | blocks nothing |
| Cost | contention | old versions taking space until cleaned up |

Cleanup is the part that shows up in production. Postgres calls it vacuum, and it removes versions no active transaction can still need. If a transaction stays open for hours, nothing newer than its start can be cleaned, so dead rows pile up and the table bloats even though its live row count never changed.

> [!warning] MVCC prevents blocking, not lost updates
> Two transactions can both read 100, both add 10, and both write 110. Getting 120 requires either `SELECT ... FOR UPDATE` or a version check, so read-modify-write still needs care. See [[locks]] for the choice.

**Shows up in:** [[read-lock-contention]], [[write-path-basics]], [[query-optimization]], [[sql-vs-mongodb]], [[write-scaling]], [[sharding-and-scale]].

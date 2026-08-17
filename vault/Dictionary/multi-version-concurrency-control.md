# Multi-Version Concurrency Control (MVCC)

> [!tldr]
> Readers and writers never block each other because each transaction sees its own snapshot of the data, taken at the moment it started.

Instead of locking a row for a write, the database keeps several versions of it and hands each transaction the version consistent with its own start time. Old versions get cleaned up later, which is what Postgres vacuum does.

This is why a long running read does not stall writes. It also means a read can see slightly stale data, and unremoved old versions bloat storage until cleanup catches up.

**Shows up in:** [[read-lock-contention]], [[write-path-basics]], [[query-optimization]].

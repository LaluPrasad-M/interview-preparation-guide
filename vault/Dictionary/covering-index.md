# Covering Index

> [!tldr]
> An index that already contains every column a query needs, so the database can answer straight from the index without a second trip to fetch the row.

Without one, the database traverses the index then jumps to the heap for the remaining columns, and at scale that extra heap fetch is expensive random I/O. A covering index turns that into an index only scan.

The cost is a bigger index and slower writes, since now the write has to update that wider index too.

**Shows up in:** [[query-optimization]], [[indexing]], [[study-roadmap]].

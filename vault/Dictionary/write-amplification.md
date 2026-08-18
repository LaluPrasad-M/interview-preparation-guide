# Write Amplification

> [!tldr]
> One logical write becomes many physical writes, because indexes, logs, replicas and storage bookkeeping all have to be updated for the same change.

You inserted one row. The disk did considerably more than one thing.

> [!example]- Counting the writes behind one `INSERT`
> A table with 4 indexes takes one new row.
>
> ```text
> 1   the row itself
> 4   one entry per index
> 5   write ahead log entries covering all of the above
> x2  again on each replica
> ```
>
> So a single logical insert becomes roughly 20 physical writes across the cluster. That is the number your disks and your replication link actually see, and it is why a write heavy table with many indexes slows down in a way the row count never explains.

Some choices make it much worse than that baseline.

| Choice | What it does |
| --- | --- |
| Random UUID primary key | inserts land all over the B-tree, so pages split and rewrite constantly |
| Time ordered ID such as ULID | inserts append to the same end of the tree, far less rewriting |
| One extra index nobody queries | a full extra write on every insert and update, forever |
| Adding a field to a large embedded document | the whole document is rewritten, not the field |
| Log structured storage, as in RocksDB | compaction rewrites the same data repeatedly in the background |

> [!tip] The read gain is paid for on the write path
> An index makes one query faster and every write slower, which is a fine trade until you have eight of them on your busiest table. The counting exercise above is the fastest way to justify deleting one.

**Shows up in:** [[write-path-basics]], [[distributed-id-generation]], [[embedding-and-referencing]].

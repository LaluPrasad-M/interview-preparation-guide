# Write Ahead Log (WAL)

> [!tldr]
> The database writes down what it is about to do before it does it, so a crash in the middle can be replayed and finished rather than left half applied.

Every change is appended to a log file first, and the actual data pages are updated later. The order is the whole point: once the log entry is safely on disk the transaction can be reported as committed, because the change can now be reconstructed even if the machine dies before the pages are touched.

Appending is fast because it is one sequential write to the end of one file. Updating the real pages is slow because they sit scattered across the disk, so the database batches that work and does it in the background.

> [!example]- What a crash actually costs
>
> ```text
> commit   change appended to the log, flushed with fsync, client told "committed"
> crash    power cut before the data pages were updated
> restart  database reads the log, replays anything the pages are missing
> ```
> Nothing committed is lost, and the recovery time depends on how much of the log had not been applied yet. Without the log, a crash mid update leaves a page half written and the table is corrupt.

The log turns out to be useful for far more than crashes, because it is an ordered record of every change ever made.

| Also built on the log | How |
| --- | --- |
| Replication | followers replay the leader's log entries |
| Change data capture | a consumer tails the log and publishes each change |
| Point in time recovery | restore a snapshot, then replay the log up to a chosen moment |

> [!tip] Durability comes from the flush, not the append
> The entry is only safe once it has actually reached the disk, which is why every commit involves an [[fsync]] and why batching those flushes is how throughput is recovered.

**Shows up in:** [[write-path-basics]], [[change-data-capture]], [[write-scaling]], [[billing-ledger]], [[api-failures-financial]], [[flash-sale-inventory]], [[idempotency]], [[multi-region-cart]].

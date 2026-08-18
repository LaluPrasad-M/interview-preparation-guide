# fsync (File Sync)

> [!tldr]
> The system call that forces the operating system to actually push buffered writes onto the disk, instead of leaving them in memory where a crash would lose them.

When your code writes to a file, the write usually returns before the data has reached the disk. The operating system keeps it in a memory area called the page cache and flushes it later, because that makes writes look fast. Memory does not survive a power cut, so until `fsync()` returns, "the write succeeded" only means "the write is queued".

> [!example]- Why databases pay for it anyway
> A database appends the change to its write ahead log, then calls `fsync()` before telling you the transaction committed.
> One `fsync` costs roughly 0.5 to 1 ms on a decent SSD, and it cannot be parallelised away.
>
> | Policy | Writes per second, one thread | What a crash loses |
> | --- | --- | --- |
> | `fsync` after every write | around 1,000 | nothing |
> | `fsync` once per 100 writes | around 100,000 | up to 100 writes |
> | never `fsync` | as fast as memory | everything still buffered |
>
> Batching is the standard answer, which is exactly [[amortised-analysis]] applied to disk: one slow flush shared across many cheap appends. It is also why a database commit can be grouped with other commits happening at the same moment.

Redis exposes this choice as a config setting rather than hiding it. `appendfsync always` is durable and slow, `everysec` risks about one second of writes, and `no` leaves it entirely to the operating system.

> [!warning] "The write returned" is not "the data is safe"
> This is the gap behind a lot of surprising data loss: the application logged success, the disk never got the bytes, and the crash landed in between. See [[write-ahead-log]] for what the log is doing with those flushed bytes.

**Shows up in:** [[write-path-basics]], [[write-scaling]], [[appointment-scheduler]], [[flash-sale-inventory]], [[sharding-and-scale]].

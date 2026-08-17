# fsync

> [!tldr]
> The system call that forces the operating system to flush buffered writes to durable storage, instead of trusting them to a volatile cache.

RAM and the OS page cache are both volatile, so anything sitting only in them disappears on a crash. Databases call `fsync()` after appending to the write ahead log to make each entry durable.

The call is slow relative to the append itself, so batching many writes into one `fsync` is the standard way to keep durability without collapsing throughput.

**Shows up in:** [[write-path-basics]], [[appointment-scheduler]], [[flash-sale-inventory]].

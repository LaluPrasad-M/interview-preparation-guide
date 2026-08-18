# Backpressure

> [!tldr]
> A slow consumer tells a fast producer to hold off, so the fast side does not bury the slow side in unbounded queued work.

A Node stream pauses the source when the destination cannot keep up (`pause()`, `resume()`), which is why streaming a large file stays at constant memory instead of buffering the whole thing. The same idea runs a system wide: Kafka consumer lag, a bounded queue, or an API deliberately rejecting requests once it is overloaded.

Without it, an overloaded consumer just keeps accepting work until it runs out of memory instead of failing predictably.

**Shows up in:** [[timeouts-and-circuit-breakers]], [[express-internals]], [[nfr-decision-table]].

# Thundering Herd

> [!tldr]
> A hot cache key expires and every waiting request rebuilds it at the same instant, turning one expiry into a spike of duplicate database load.

Also called a cache stampede. Nothing coordinates the requests that were all reading the same key, so the moment it disappears they all fall through together and hit the origin at once.

The fix is to make only one of them actually do the rebuild: request coalescing, a distributed lock, or staggered TTLs so keys do not all expire in the same instant.

**Shows up in:** [[caching-problems]], [[appointment-scheduler]], [[redis-use-cases]].

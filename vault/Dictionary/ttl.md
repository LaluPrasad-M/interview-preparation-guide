# TTL (Time To Live)

> [!tldr]
> How long a piece of data is allowed to stay valid before it expires, after which it must be refreshed or refetched.

A cache key set with a TTL disappears automatically once that window passes, so stale data cannot linger forever without someone actively invalidating it. The same idea sizes a session, a lock, or a DNS record: a number that trades freshness against how often the underlying value has to be looked up again.

Picking it is a trade off, not a default. Too short and it stops saving anything; too long and it hides real changes.

**Shows up in:** [[caching-problems]], [[redis-use-cases]], [[flash-sale-inventory]], [[realtime-leaderboard]].

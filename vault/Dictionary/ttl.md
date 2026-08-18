# Time To Live (TTL)

> [!tldr]
> How long a piece of data is allowed to stay valid before it expires by itself. It is the promise that stale data will clear out even when nobody remembers to clear it.

Set a Redis key with a 60 second TTL and it disappears 60 seconds later without anyone doing anything. That matters because the alternative, invalidating a cache entry at the exact moment the underlying value changes, is one of the hardest things to get right in a distributed system. A TTL is the safety net under it: whatever you missed, it goes away within a bounded window.

The same number sizes several different things, and the choice is a trade off in each.

| Where | Too short | Too long |
| --- | --- | --- |
| Cache key | almost every read misses, so the cache stops helping | users see data that changed minutes ago |
| Session | users get logged out mid task | a stolen token stays useful for longer |
| Distributed lock | expires while the work is still running, so two workers act | a crashed holder blocks everyone until it lapses |
| DNS record | more lookups, slower first connections | a failover cannot take effect until it expires |

> [!warning] Do not give every key the same TTL
> Cache 10,000 keys at startup with a flat 300 second TTL and all 10,000 expire on the same tick, which is a [[thundering-herd]] you scheduled yourself. Add random jitter, something like 300 seconds plus or minus 30, and the expiries spread out.

> [!tip] Pick it from how stale the data may be
> Start from the product question, which is how out of date this value is allowed to look to a user, not from a number that feels safe. A price needs seconds, a country list can sit for a day.

**Shows up in:** [[caching-problems]], [[redis-use-cases]], [[caching-and-errors]], [[patterns-worth-stealing]], [[appointment-scheduler]], [[flash-sale-inventory]], [[realtime-leaderboard]], [[url-shortener]].

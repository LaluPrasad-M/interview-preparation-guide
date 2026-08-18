# Thundering Herd

> [!tldr]
> A popular cache key expires, and every request that wanted it rebuilds it at the same instant. One expiry turns into a flood of identical database queries. Also called a cache stampede.

Nothing coordinates those requests. They were all being served happily from cache a millisecond ago, and the moment the key disappears they all fall through together, because none of them knows the others are doing the same work.

> [!example]- One key, 5000 requests a second
> A product page is read 5000 times a second and cached for 60 seconds, so the database sees roughly one query per minute.
> The key expires. In the few hundred milliseconds it takes to rebuild, around 1500 requests arrive, miss, and each starts its own rebuild.
> The database goes from 1 query per minute to 1500 at once, and if it slows down under that load the rebuild takes longer, so even more requests pile in behind. That feedback loop is what turns a cache miss into an outage.

The fixes all come down to letting exactly one request do the work.

| Fix | How it works |
| --- | --- |
| Request coalescing | the first miss rebuilds, later misses wait on that same in flight promise |
| Distributed lock | one process takes a short lock and rebuilds, others serve stale or wait briefly |
| Serve stale while revalidating | keep the old value past expiry and refresh it in the background |
| Staggered TTLs | add random jitter so 10,000 keys do not expire on the same tick |

> [!tip] It is the same shape as retry storms
> A synchronised crowd all doing the correct thing at the identical moment is the pattern. The cure is always to break the synchronisation, with jitter, or to elect one doer, which is why this sits next to [[exponential-backoff]] and [[cold-start]].

**Shows up in:** [[caching-problems]], [[appointment-scheduler]], [[redis-use-cases]], [[caching-and-resilience]], [[circuit-breaker]], [[ai-tool-idempotency]], [[production-prompts]].

# Cold Start

> [!tldr]
> The first request after a restart, deploy or expiry hits a system with no warm state to draw on, so it is slower or heavier than normal.

For a cache, cold start means the cache is empty after a restart or a deploy, so the next wave of requests all fall through to the database at once instead of being served from memory. The same word describes a serverless function spinning up a fresh container before it can handle a request.

Warm-up strategies (preloading a cache, keeping functions pinged) exist specifically to avoid paying this cost on the traffic that matters.

**Shows up in:** [[caching-problems]], [[caching-and-resilience]], [[redis-use-cases]], [[feature-flags]].

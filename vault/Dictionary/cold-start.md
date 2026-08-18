# Cold Start

> [!tldr]
> The first request after a restart, a deploy or an expiry lands on a system with nothing warmed up yet, so it is slower and heavier than every request after it.

Warm state is anything a system builds up while it runs and loses when it stops: cached values, open database connections, compiled code, a container that is already booted.

> [!example]- Two cold starts, same idea
> **An empty cache after a deploy.** Normally 95 percent of reads are served from Redis and only 5 percent reach the database. Right after a restart the cache holds nothing, so 100 percent reach the database at once. If the database was sized for 5 percent of traffic, the deploy itself takes the site down.
>
> **A serverless function that has not run in a while.** The platform has to fetch your code, start a container and initialise the runtime before your handler even begins. That is roughly 200 ms to 1 second on the first call against about 5 ms once the container is reused.

| Where it bites | What is missing | The usual fix |
| --- | --- | --- |
| Cache | keys, after a restart or a mass expiry | warm the hot keys before taking traffic |
| Serverless function | a booted container | keep a few instances always warm, or ping on a timer |
| Database connection pool | established connections | open the pool at startup, not on first request |
| JavaScript or Java runtime | code the engine has optimised | let a readiness probe hold traffic back until it has run a little |

> [!tip] This is why deploys are a latency event
> A readiness probe that only checks "the process started" sends traffic to a pod with an empty cache and an empty pool. Checking "I can actually answer a real query" is what turns a cold start from an outage into a shrug.

**Shows up in:** [[caching-problems]], [[caching-and-resilience]], [[redis-use-cases]], [[feature-flags]].

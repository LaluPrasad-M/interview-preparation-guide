# Caching and Resilience

> [!tldr]
> Read scaling begins with caching and replicas to reduce database load, then evolves into resilience engineering when traffic spikes expose concurrency and retry amplification failures.

Part of [[read-scaling]].

---

## Stage 0: the initial simple system

We start with `Client -> API -> PostgreSQL`.

At small scale this is completely fine: simple, easy to debug, strongly consistent, minimal infrastructure complexity.

This is important. A lot of engineers prematurely jump into Redis, Kafka, microservices and replicas, but at small scale that complexity is unnecessary. Initially this architecture is genuinely good.

Now suppose the user count grows, traffic grows, celebrity profiles become popular, and users repeatedly refresh profiles. PostgreSQL becomes overloaded: DB CPU rises, query latency increases, p99 spikes, APIs slow down.

At this stage the bottleneck is repetitive expensive reads hitting the primary DB. So the question is: what is the cheapest and most impactful optimisation? The answer is caching, not replicas, not sharding, not Kafka, because the problem is repeated identical reads and that naturally suggests reusing previous results.

---

## Stage 1: introducing a Redis cache

Architecture becomes `Client -> API -> Redis -> PostgreSQL`.

The API checks Redis. On a hit it returns immediately. On a miss it fetches from PostgreSQL, populates Redis, and returns.

This dramatically reduces repeated DB reads, query execution load, connection pressure, and disk and memory pressure on PostgreSQL.

But now `DB state != Cache state` becomes possible. A user updates their profile, PostgreSQL is updated, the Redis update fails, and stale data appears. So Redis reduced DB pressure but introduced synchronisation complexity, invalidation problems, and stale reads. That is the first major tradeoff.

Then another issue appears. A celebrity profile goes viral, the cache entry expires, and millions of requests miss the cache simultaneously. All of them hit the DB together, which is a cache stampede.

This is why systems introduce TTL jitter, stale while revalidate, request coalescing, and background refresh. Notice the pattern: every optimisation introduces another protection layer. This is exactly how real systems evolve.

---

## Stage 2: Redis itself becomes the bottleneck

Traffic keeps growing. One celebrity goes globally viral and millions of users repeatedly request the same key.

Traffic distribution becomes uneven. Earlier the average traffic mattered; now hotspot traffic matters. One Redis shard gets overloaded because `profile:celebrity:taylor_swift` always hashes to the same location, and Redis latency spikes.

We are no longer bottlenecked by PostgreSQL. Redis became the bottleneck.

> [!tip] Bottlenecks migrate
> Optimisations rarely remove bottlenecks permanently. They shift them elsewhere.

The natural next optimisations: CDN, local in memory cache, replicated cache entries, request coalescing.

Notice we are progressively moving farther away from the database, because database access is expensive. Systems try to terminate requests at the CDN, at the edge cache, and at Redis, before reaching the DB. That is the natural evolution of read heavy systems.

---

## Stage 3: the database is still under pressure

Even after Redis, some requests still hit PostgreSQL: cache misses, cold starts, expired entries, uncached queries, analytical queries.

Can we distribute reads across multiple DB instances? That introduces read replicas.

```text
                -> Replica 1
API -> Redis -> Primary DB
                -> Replica 2
                -> Replica 3
```

Reads distribute across replicas, which reduces primary DB read pressure, query concurrency and CPU contention.

But replication is asynchronous, so a write can succeed while the replica is still stale, and users may see outdated data. Replicas solved read scalability but introduced eventual consistency, stale reads, replication lag, and failover complexity. Optimisation introduced new tradeoffs again.

---

## Stage 4: traffic spikes create concurrency collapse

Traffic becomes extremely bursty. A celebrity posts a viral tweet and traffic jumps from 10k RPS to 500k RPS.

Initially everything still works, but Redis latency slightly increases. This is where one of the deepest transitions happens. Earlier requests completed quickly; now requests stay alive longer, which increases active sockets, memory occupancy, unresolved promises, DB waiting, and queue buildup.

Latency transforms into concurrency pressure.

At this point the system does not fail because CPU instantly hits 100 percent. It fails because waiting accumulates faster than processing. That is the birth of queueing collapse, retry amplification and occupancy explosion, and it is where systems enter cascading failure territory.

---

## Stage 5: retries begin destroying the system

Clients experience timeouts, so naturally they retry. That seems harmless, but retries are additional traffic generation.

Now system traffic becomes original traffic plus retry traffic plus retry of retry traffic. Load increases even though real user traffic did not increase. That is a retry storm, and it forms a positive feedback loop: queues grow faster, latency increases, more retries happen.

So overload protection itself becomes necessary architecture. Earlier we optimised for performance; now we optimise for survival.

---

## Stage 6: connection pools become the real bottleneck

The database may still be alive, but requests now wait for DB connections, Redis connections and network sockets.

Many systems appear down when the actual issue is connection occupancy exhaustion.

> [!warning] The insight to keep
> Resources are not merely consumed by work. They are consumed by waiting.

This introduces pool sizing, queue limits, admission control, request cancellation, and timeout strategy. Another layer of protection architecture.

---

## Stage 7: the system needs resilience engineering

The architecture is no longer merely optimised; it must become resilient under overload.

This introduces backpressure, load shedding, circuit breakers, graceful degradation, stale reads and prioritisation.

The system begins intentionally sacrificing freshness, completeness and low priority traffic in order to preserve core functionality. That is mature distributed systems engineering.

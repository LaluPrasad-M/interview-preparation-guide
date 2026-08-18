# Caching Problems

> [!tldr]
> Twelve ways caching bites back. [[ttl|TTL]] is not a performance setting, it is a consistency policy.

---

## 1. Cache stampede, the thundering herd

A [[hot-key|hot cache key]] expires and many requests hit the database simultaneously, because all of them try to rebuild the cache at the same time.

**Mitigations.** Request coalescing or single flight, where only one request fetches and the others wait for the result. Distributed locking with `SETNX`. Stale while revalidate. Randomised TTL, meaning jitter. Background refresh. Never expiring ultra hot keys. [[cdn|CDN]] offloading. Local in memory caching.

**The insight.** A stampede is a traffic amplification problem.

---

## 2. Cache avalanche

A large number of keys expire together, causing many misses and a sudden database spike.

| Issue | Meaning |
| --- | --- |
| Stampede | one hot key expires |
| Avalanche | many keys expire together |

**Mitigations.** Randomised TTL, staggered expirations, cache warmup, background refresh.

---

## 3. Cache penetration

Requests repeatedly query data that does not exist, so invalid keys bypass the cache and hit the database every time. This can be malicious.

**Negative caching.** Cache the `NULL` or `NOT_FOUND` result for a short TTL.

**[[bloom-filter|Bloom filters]].** These run before the database lookup. A bloom filter answers either definitely not present, or maybe present. There are no false negatives, so it massively reduces useless database queries.

---

## 4. Cache invalidation

The database is updated but the cache still holds stale data.

**The common cache aside pattern.** On read, a cache miss goes to the database and populates the cache. On write, update the database then delete the cache.

> [!warning] The critical race condition
> Request A reads the old database value. Request B updates the database and deletes the cache. Request A then writes its stale value into the cache.

**Mitigations.** Delayed double delete, versioned cache keys, event driven invalidation, short TTL.

**The insight.** Invalidation is hard because the cache and the database are separate distributed systems.

---

## 5. Cache consistency

The cache and database diverge. Caching always weakens consistency, so the real question becomes how much staleness is acceptable.

**Mitigations.** Write through cache, event driven updates, short TTLs, critical reads bypassing the cache, or simply accepting eventual consistency.

> [!tip] The insight
> TTL is effectively a consistency policy. A long TTL means better performance and more stale data. A short TTL means fresher data and more database load.

---

## 6. Hot keys and hot partitions

One key receives huge traffic: a viral post, flash sale inventory, a celebrity profile.

**The insight.** This usually becomes a CPU or network bottleneck, not a memory bottleneck.

**Mitigations.** A local L1 cache, key replication, CDN, better sharding, consistent hashing.

```text
Application Memory
    |
  Redis
    |
 Database
```

---

## 7. Cold start

The cache is empty after a restart or deployment, causing sudden database overload.

**Mitigations.** Cache warmup, preloading hot keys, Redis persistence via RDB or AOF.

---

## 8. Eviction

Important entries are removed under memory pressure.

| Policy | Meaning |
| --- | --- |
| LRU | least recently used |
| LFU | least frequently used |
| FIFO | oldest removed |
| TTL | closest expiry removed |

LFU is often better for hot key workloads.

---

## 9. Distributed cache synchronisation

Multiple app servers hold local caches. One updates the data and the others stay stale.

**Mitigations.** Redis pub/sub invalidation, event driven invalidation, a centralised distributed cache.

**The insight.** Multi level caching improves latency but increases invalidation complexity.

---

## 10. Serialisation overhead

Large cached objects increase CPU usage, GC pressure, latency and network cost, especially in a single threaded runtime.

**Mitigations.** Cache smaller objects, partial caching, binary serialisation, selective compression.

---

## 11. Redis single thread blocking

Redis executes commands mostly single threaded, so one expensive command blocks the entire instance.

**The dangerous operations.** `KEYS *`, large scans, huge Lua scripts.

**The mitigation.** Avoid O(N) operations on hot production nodes. Use `SCAN` instead of `KEYS`.

---

## 12. Write policy trade offs

| Policy | Behaviour | Risk |
| --- | --- | --- |
| Write through | write DB and cache together | slower writes |
| Write behind | cache first, DB later | data loss risk |
| Write around | skip the cache on writes | more cache misses |

**The most common production setup.** Cache aside plus Redis plus TTL plus event invalidation.

---

## The 20 percent hit ratio question

This is a classic senior debugging prompt. A hit ratio of 20 percent means 80 percent of requests still reach the database, so either the cache is not useful, it is misconfigured, or the workload does not benefit from caching.

### Step 1: clarify the context first

Is this read heavy? Is traffic uniform or skewed? What is the TTL? What is the eviction policy? What is the cache size? Which keys are being cached?

Senior engineers do not jump to conclusions.

### Step 2: the six root causes

**High [[cardinality]] keys.** If every request uses a different key, for example `GET /users/{id}` with traffic spread evenly across millions of users, there is no reuse. Low locality means a low hit ratio.

**TTL too small.** If the TTL is 5 seconds but the same key is requested every 30 seconds, the cache always expires before reuse. Check the TTL against the real request frequency per key.

**Wrong cache layer.** You cache in the application, but traffic is spread across many pods with no shared Redis. Each pod has its own small cache, so the effective hit ratio collapses.

**Memory evictions.** If Redis memory is small, keys are evicted frequently. Check the eviction count, the eviction policy and memory usage percentage.

**Poor access pattern.** Pagination where most users request each page once has almost no reuse.

**[[cold-start|Cold cache after deployment]].** After a restart the cache is empty and initial misses are high.

### Step 3: the metrics to check

Hit ratio, both global and per key. Evictions per minute. Memory usage percentage. Keyspace size. P95 and P99 latency. Database [[qps|QPS]]. Top requested keys, for skew analysis.

> [!tip] The scripted answer
> A 20 percent hit ratio suggests either high cardinality, a low TTL, memory pressure, or incorrect cache placement. I would first check the eviction rate, memory usage and key access patterns. If the access pattern has low reuse, caching may not help at all. Otherwise, tuning the TTL and the cache size should improve it.

---

## What a cache entry actually holds

```js
{
  key: value,
  expiresAt: timestamp,
  lastAccessed: timestamp,
  frequency: count
}
```

That shape is why the eviction policies work: `lastAccessed` is what LRU tracks, and `frequency` is what LFU tracks.

---

## TTL against lock control

These solve different problems and are often confused.

| Feature | TTL | Lock control |
| --- | --- | --- |
| Purpose | expire stale values | prevent concurrent fetches and writes |
| Helps with | freshness, memory | concurrency, race conditions |
| Prevents | stale reads | cache stampede, inconsistent writes |
| Implemented as | `EX <seconds>` on keys | `SETNX lock:<key>` |
| When used | after the value is cached | before the value is fetched or persisted |

---

## The fourth write strategy: refresh ahead

The write policy table above covers write through, write behind and write around. The fourth option is refresh ahead: the cache refreshes the value **before** the TTL expires.

This is good for frequently read values, and it avoids the stale window entirely, at the cost of refreshing things nobody asked for.

---

## The golden interview line

> [!tip] Say this
> Caching improves latency and scalability. But it introduces distributed systems trade offs: consistency, invalidation, synchronisation, expiration spikes and uneven traffic distribution. Production systems mitigate these with request coalescing, stale while revalidate, bloom filters, randomised TTLs, local L1 caches, event driven invalidation and careful eviction strategies.

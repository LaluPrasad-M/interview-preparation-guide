# Redis Use Cases

> [!tldr]
> Ten things Redis is genuinely the right tool for, and the Node implementation of the two that come up most.

---

## 1. Caching, the most common use

Avoid hitting the database for repeated reads.

**Patterns.** Read through, write through or write back, and cache aside, which is the most common.

**Examples.** User profile cache, product catalog, feature flags, config values.

```text
Service -> Redis -> DB (on cache miss)
```

The buzzwords to mention: cache invalidation, TTL, hot keys, cache stampede. See [[caching-problems]].

---

## 2. Distributed locking

Prevent race conditions across multiple service instances.

**Use cases.** Preventing double order placement, ensuring a single cron or job execution, basic leader election.

**The primitive.** `SET key value NX PX`. Acquire the lock, run the critical section, release the lock.

Mention the Redlock algorithm even if you would not implement it.

---

## 3. Rate limiting and throttling

Protect APIs from abuse and overload: login attempts, OTP requests, public APIs, per user and per IP limits.

**The tools.** `INCR` plus `EXPIRE`, sliding window, or token bucket implemented with Lua.

```text
API Gateway -> Redis -> Allow / Reject
```

---

## 4. Session store

Keep services stateless while storing user sessions centrally: auth tokens, cart sessions, temporary user state.

Redis fits because of low latency, TTL based expiration and horizontal scaling.

---

## 5. Lightweight message queue

Decouple producers and consumers using lists, `LPUSH` and `BRPOP`, or the more modern streams.

**Use cases.** Background jobs, email sending, basic event fan out.

Mention the limitation against Kafka: durability and replay. See [[kafka-vs-rabbitmq]].

---

## 6. Pub/sub for event broadcasting

Real time event propagation for WebSocket notifications, cache invalidation signals, and feature flag updates.

```text
Service A -> Redis Pub/Sub -> Service B, C, D
```

Note there is no persistence, and delivery is best effort. See [[websocket-bridge]].

---

## 7. Leaderboards and counters

Atomic operations plus sorted data, using `INCR` and sorted sets with `ZADD` and `ZRANK`.

**Examples.** Top users, most viewed items, real time metrics. See [[realtime-leaderboard]].

---

## 8. Idempotency handling

Prevent duplicate processing of payment requests, webhook handling and retry safe APIs.

**The pattern.** Request ID, then `SETNX`, then process once. See [[idempotency]].

---

## 9. Feature flags and dynamic config

Change behaviour without redeploying: enabling and disabling features, gradual rollouts, kill switches. See [[feature-flags]].

---

## 10. Service coordination and metadata

Lightweight shared state: active workers, heartbeats, job ownership, shard assignments.

---

## The cache aside implementation

```js
const redis = require("redis");
const client = redis.createClient();

client.connect();

async function getCachedValue(key, fetchFunction, ttl = 300) {
    // 1. Try reading from cache
    const cached = await client.get(key);

    if (cached) {
        console.log("CACHE HIT:", key);
        return JSON.parse(cached);
    }

    console.log("CACHE MISS:", key);

    // 2. Fetch from the source
    const freshValue = await fetchFunction();

    // 3. Store in cache with a TTL
    await client.set(key, JSON.stringify(freshValue), { EX: ttl });

    return freshValue;
}
```

---

## Adding a lock to stop the stampede

> [!tip] The interview line
> When multiple service instances try to fetch the same expensive data, a cache stampede occurs. A `getWithLock()` uses `SETNX` as a distributed lock so only one instance fetches fresh data while the others wait and retry. Once the data is set, all services consume from cache. The TTL protects from deadlocks if a process crashes.

### The problem without a lock

Four services receive a request at the same time and the cache is empty, either a cold start or an expired TTL.

```text
A: Cache miss -> calls the expensive upstream
B: Cache miss -> calls the expensive upstream
C: Cache miss -> calls the expensive upstream
D: Cache miss -> calls the expensive upstream
```

Four expensive calls, all unnecessary, potentially overloading the upstream.

### Scenario 1: all four hit simultaneously

**At 0 ms.** All four call `client.get("publicKey")`. The cache is empty, so all proceed to `acquireLock("lock:publicKey")`.

**At 1 to 2 ms.** Service A runs `SETNX lock:publicKey` and succeeds, so A is the fetcher. Services B, C and D fail the `SETNX`, so they do not fetch. They wait 100 ms and retry.

**At 20 to 100 ms.** Service A starts the expensive fetch, which might take 300 to 800 ms. B, C and D keep retrying, find the cache still empty and the lock still taken, and wait again. No stampede, no duplicate requests.

**At 900 ms.** A finishes, sets the cache with a TTL, and deletes the lock.

**At 901 ms.** B, C and D retry, get a cache hit, and immediately return the cached value. No upstream call at all.

| Service | Upstream call? | Cache wait? | Returned |
| --- | --- | --- | --- |
| A | yes, 1 call | no | fresh data, and writes to cache |
| B | no | roughly 100 to 200 ms | cached data |
| C | no | roughly 100 to 200 ms | cached data |
| D | no | roughly 100 to 200 ms | cached data |

Upstream calls reduced by 75 percent, the race condition prevented, the thundering herd avoided.

### Scenario 2: service A crashes holding the lock

A acquires the lock, starts fetching, and crashes halfway without unlocking. The lock has `EX 5`, so it auto expires after 5 seconds.

B, C and D keep checking, find the cache empty and the lock active, and do not fetch. After the TTL expires, B acquires the lock and fetches, and everyone else waits and gets cached data.

No deadlock and no system wide failure. This is why we always put a TTL on locks.

### Scenario 3: TTL expiry

When the TTL ends, the next request behaves like a cold start. The first service gets the lock, others wait, the first populates the cache.

### Scenario 4: high traffic with a warm cache

At 1,000 requests per second spread across four services, the cache is available so every request is a hit. `client.get()` is sub millisecond, and there are zero upstream calls.

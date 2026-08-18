# URL Shortener

> [!tldr]
> Base62 over an auto increment ID, not random strings. Cache first on reads, async analytics, and shard by short code so the distribution stays even.

The capacity numbers for this system are worked in [[capacity-estimation]].

---

## Framing it

Reads outnumber writes by 10 to 100 times. Strong consistency is not required, and eventual consistency is acceptable. Saying that up front already puts you above average.

---

## The API

```text
POST /shorten
{
  "longUrl": "https://example.com/very/long/url",
  "customAlias": "my-link",
  "expiry": "2026-01-01"
}
```

```json
{ "shortUrl": "https://sho.rt/Ab3kP9" }
```

```text
GET /Ab3kP9
-> 302 redirect to the long URL
```

> [!tip] 302 against 301
> 302 allows analytics and flexibility. 301 gets cached aggressively by browsers, so you stop seeing the traffic. See [[http-status-codes]].

---

## The data model

```json
{
  "shortCode": "Ab3kP9",
  "longUrl": "https://example.com/...",
  "createdAt": "timestamp",
  "expiresAt": "timestamp",
  "clickCount": 0
}
```

The access pattern is `shortCode` to `longUrl`. The short code must be unique, short, fast to generate, and evenly distributed, which matters for sharding.

---

## Generating the short code

This is the heart of the problem.

**Random strings.** This approach causes collisions, needs retry logic, and is hard to scale globally.

**An auto increment ID converted to Base62.** Generate a unique numeric ID, convert to Base62 over `[a-zA-Z0-9]`. ID 125 becomes `"cb"`.

> [!question] Why Base62 rather than Base64?
> Base64 contains `+` and `/`, which need URL escaping and can interfere with routing and parsing. Base62 is alphanumeric only, so it is URL safe with no extra encoding, while still giving a large enough space for compact IDs.

### Generating unique IDs at scale

A single database auto increment is a bottleneck and a single point of failure.

Instead use distributed ID generation: database range allocation, Snowflake style IDs, or a dedicated ID service. The interview safe version is that each app server claims a block of IDs, for example a million at a time, and hands them out locally. See [[distributed-id-generation]].

---

## The architecture

```text
Client
  |
Load Balancer
  |
URL Shortener Service
  |
Cache (Redis)
  |
Database (shards + replicas)
```

**The read path,** which is latency critical: the user hits the short URL, the service checks the cache, falls through to the database on a miss, returns the long URL, and updates analytics asynchronously.

We cache first because reads dominate, latency needs to be sub millisecond, and caching protects the database from spikes.

**The write path:** validate the URL, generate the ID, encode to Base62, persist, populate the cache, respond. Writes are far less frequent, so slightly higher latency is fine.

---

## Scaling

**Sharding.** Shard by `shortCode`, which distributes evenly. Sharding by `createdAt` creates hotspots, because all new writes land on one shard.

**Replication.** The leader handles writes, replicas serve reads, and the cache absorbs most reads anyway.

**Cache.** Key `shortCode` to `longUrl`, LRU eviction, [[ttl|TTL]] aligned with expiry. Mitigate a miss storm with cache warmup and request coalescing. See [[caching-problems]].

**[[cdn|CDN]].** Caching redirect responses at the edge reduces global latency and offloads an enormous share of reads.

**Analytics.** Never update the database synchronously on redirect. Fire an event to Kafka and let an analytics service consume it.

---

## Failure scenarios

**Cache down.** Fall back to the database. The system still works, just slower.

**Database primary down.** Fail over to a replica, with writes paused briefly.

**Duplicate short codes.** This is avoided entirely by the ID strategy. If you chose random generation, you need retry logic.

---

## Abuse and cleanup

Rate limit per IP, validate URLs, blacklist malicious domains, and prevent infinite redirects.

For expired URLs, run a periodic background job, soft deleting first and hard deleting later.

---

## The trade offs to call out

| Choice | Why |
| --- | --- |
| Base62 | short and URL safe |
| Cache first reads | latency and scale |
| Eventual consistency | performance over strict correctness |
| Async analytics | fast redirects |
| Sharding | horizontal scalability |

---

## How to speak it

Use phrases like "given read heavy traffic", "to avoid hotspots", "at scale this becomes a bottleneck", and "we can trade strong consistency for availability here".

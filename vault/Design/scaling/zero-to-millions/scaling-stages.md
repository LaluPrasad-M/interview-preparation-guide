# Scaling Stages, Zero to Millions

> [!tldr]
> Nine numbered stages trace the evolution from a single server to a distributed system, each stage introducing new architectural components in response to previous bottlenecks.

Part of [[zero-to-millions]].

---

## Stage 0 to 1: single server monolith

```text
Client -> Web Server
              |- App Logic
              +- Database
```

Everything runs on one machine. It is simple to build and deploy, and it works for few users and low traffic.

**Terminology.** A monolith bundles UI, business logic and DB tightly together. Vertical scaling, or scaling up, means increasing the CPU and RAM of the same server.

**Bottlenecks.** CPU saturation, memory limits, and a single point of failure.

**The line to say.** At very low traffic, a single server monolith is acceptable due to simplicity, but it does not scale or provide fault tolerance.

---

## Stage 2: separate web server and database

```text
Client -> Web Server -> Database Server
```

**Why.** The DB is usually the first bottleneck, and this allows independent scaling of the DB and the app.

**New terms.** Two tier architecture. Read and write contention, meaning multiple requests fighting for DB access. Connection pooling, reusing DB connections.

**Improvement.** The app can scale without touching DB hardware.

---

## Stage 3: load balancer plus multiple app servers

```text
Client
   |
Load Balancer
   |
App Server 1
App Server 2
App Server 3
   |
Database
```

**Core concepts.** Horizontal scaling, or scaling out, adds more servers. Stateless servers store no user data in memory. Load balancing algorithms include round robin, least connections and IP hash.

**Key terminology.** Sticky sessions are bad for scaling. Statelessness is mandatory at scale.

**The line to say.** To scale horizontally, application servers must be stateless, otherwise load balancing becomes ineffective.

---

## Stage 4: database replication for read scaling

```text
           -> Read Replica 1
App -> Master DB
           -> Read Replica 2
```

Writes go to the primary, reads go to the replicas.

**High value terminology.** Replication lag is the delay between primary and replica. Eventual consistency. Read scalability.

| Benefit | Cost |
| --- | --- |
| more read throughput | slightly stale reads |
| fault tolerance | sync complexity |

---

## Stage 5: caching layer

```text
Client
   |
App Server
   |
Cache (Redis)
   | (cache miss)
Database
```

**Why cache.** The DB is expensive and most requests are read heavy.

**Key terms.** Cache hit and cache miss, TTL, eviction policy (LRU, LFU), hot data.

**Strategies.** Read through cache, write through cache, and cache aside (lazy loading), which is the most common.

**The line to say.** Cache is introduced to reduce database load and latency, especially for hot, frequently accessed data.

---

## Stage 6: content delivery network

A CDN is a network of geographically dispersed servers used to deliver static content. CDN servers cache static content like images, videos, CSS and JavaScript files.

```text
User -> CDN Edge -> Origin Server
```

**Used for.** Images, CSS and JS, videos.

**New terminology.** Edge server, origin server, cache invalidation, geo replication.

**Benefits.** Reduced latency, reduced origin server load, better global performance.

Dynamic content caching is a newer concept: it enables caching of HTML pages based on request path, query strings, cookies and request headers. Most courses focus on static content.

---

## The stateless web tier, in detail

To scale the web tier horizontally, move state such as user session data out of the web tier. Good practice is to store session data in persistent storage such as a relational database or NoSQL, so each web server in the cluster can access state data from the database. That is a stateless web tier.

### Stateful architecture

A stateful server remembers client data from one request to the next. A stateless server keeps no state information.

In a stateful setup, user A's session data and profile image are stored in Server 1. To authenticate user A, HTTP requests must be routed to Server 1. If a request is sent to Server 2, authentication would fail because Server 2 does not contain user A's session data. Similarly all requests from user B must go to Server 2, and all from user C to Server 3.

The issue is that every request from the same client must be routed to the same server. This can be done with sticky sessions in most load balancers, but it adds overhead. Adding or removing servers becomes much harder, and handling server failures is challenging.

### Stateless architecture

HTTP requests from users can be sent to any web server, which fetches state data from a shared data store. State data lives in the shared store and is kept out of the web servers. A stateless system is simpler, more robust and more scalable.

The shared data store could be a relational database, Memcached, Redis or NoSQL. NoSQL is often chosen because it is easy to scale.

Autoscaling means adding or removing web servers automatically based on traffic load. Once state data is removed from the web servers, autoscaling of the web tier is easily achieved.

Once the site attracts significant international traffic, supporting multiple data centers becomes crucial for availability and user experience across wider geographical areas.

---

## Stage 7: asynchronous processing with queues

```text
Client -> App -> Queue -> Worker
```

**Use cases.** Emails, notifications, image processing, analytics.

**Key terms.** Message queue, producer and consumer, backpressure, at least once delivery.

**The line to say.** Queues decouple slow or non critical work from user facing request paths.

---

## Stage 8: database sharding for write scaling

```text
Shard 1 -> User 1-1000
Shard 2 -> User 1001-2000
Shard 3 -> User 2001-3000
```

**Critical terms.** Shard key, horizontal partitioning, hot shard, re sharding.

| Pro | Con |
| --- | --- |
| massive write scaling | complex queries |
| smaller datasets | cross shard joins are hard |

---

## Stage 9: observability and reliability

**The three pillars.** Logs tell you what happened. Metrics tell you how often and how much. Traces tell you the request flow.

**Key terms.** SLI, SLO and SLA. Health checks. Circuit breaker. Auto scaling.

---

## The final evolution diagram

```text
Users
 |
CDN
 |
Load Balancer
 |
Stateless App Servers
 |
Cache -> DB (Sharded + Replicas)
 |
Message Queue -> Workers
 |
Monitoring / Logs / Alerts
```

> [!tip] The one line summary to memorise
> We start with a monolith, then introduce horizontal scaling via load balancers, cache for read performance, replication for read scaling, sharding for write scaling, CDNs for static content, queues for async processing, and observability for reliability.

# OAuth Token Lifecycle and Runtime Recovery

> [!tldr]
> Two layers, not one. A scheduler handles planned expiry, and an interceptor handles the unexpected 401. Promise sharing is what stops 100 concurrent failures becoming 100 refresh calls.

---

## The problem

A platform integrates with third party OAuth providers. Each tenant has a short lived access token and a long lived refresh token.

The requirements: avoid expired token failures, avoid refresh storms, refresh proactively, recover from unexpected 401s, handle concurrent requests safely, support multi pod scaling, and persist tokens durably.

---

## The architecture

```text
                +---------------------+
                |   Postgres DB       |
                | stores tokens       |
                +----------+----------+
                           |
                +----------v----------+
                | Background Scheduler|
                | proactive refresh   |
                +----------+----------+
                           |
                +----------v----------+
                | OAuth Provider      |
                +---------------------+
```

The runtime request flow:

```text
Application
     |
API Client
     |
Interceptor
     |
Provider API
     |
   401?
     |
Refresh Manager
     |
Retry Original Request
```

### Why both layers exist

**The proactive scheduler** solves planned token expiry. It gives smoother traffic, lower runtime failures, and avoids mass expiry spikes.

**Runtime recovery** solves unexpected invalidation: a revoked token, a stale pod cache, a delayed scheduler, or provider side invalidation.

---

## The parts

| Note | Covers |
| --- | --- |
| [[oauth-refresh-scheduler]] | proactive scheduler, token queries, gradual refresh |
| [[oauth-interceptor-and-promise-sharing]] | runtime recovery, interceptors, promise sharing, coordinated refresh |

---

## The senior concepts

**Proactive plus reactive together.** Mature systems use both. The scheduler smooths traffic, runtime recovery handles unexpected failure.

**Promise sharing.** A `Map<tenantId, Promise>` prevents the refresh storm.

**Runtime recovery is the fallback.** The scheduler is the primary architecture, the interceptor is the safety net.

**Distributed reality.** This works inside one process. Across pods you need a Redis distributed lock, which is an important discussion point.

**Why interceptors exist.** They solve cross cutting concerns: auth injection, retries, tracing, logging, metrics and token recovery, all centralised.

---

## The production gotchas

**Refresh token rotation.** Always persist the new refresh token, because the provider may invalidate the old one.

**Infinite retry loops.** Without the `_retry` flag, a 401 retries forever.

**Multiple pods.** In memory promise coordination is not enough. You need a Redis lock.

**Scheduler delay.** Never rely only on proactive refresh, because runtime recovery is still required.

---

## The final mental model

| Layer | Responsibility |
| --- | --- |
| Postgres | durable token storage |
| Scheduler | planned refresh |
| Runtime API client | outgoing API handling |
| Interceptors | centralised request and response auth logic |
| Refresh manager | preventing the refresh stampede |
| Token store | runtime token access |
| Redis | distributed locking, once you are multi pod |

# Distributed Rate Limiter

> [!tldr]
> Limit each user to N requests per window across many API servers. The design question is not which algorithm, it is where correctness comes from once several servers count the same user at the same time.

---

## The problem

Ten API servers sit behind a load balancer.
A user's requests land on any of them, so no single server sees the full count.
The limit has to hold across all of them, and the check runs on every request, so it has to be fast.

---

## Scale and correctness are two different problems

This is the part candidates blur together.

| Problem | Solved by |
| --- | --- |
| Too much traffic for one Redis node | Redis Cluster, sharded by user id |
| Redis node dying | replicas and failover |
| Two requests for one user arriving at the same moment | an atomic Lua script |
| Keeping the check cheap | O(1) Redis commands, and no locks |

> [!warning] Replicas and shards do not fix a race
> Sharding spreads load. Replicas provide availability. Neither makes `GET`, then compute, then `SET` safe, because two servers can still read the same value before either writes. Redis does not make a sequence of commands atomic just by being single threaded, see [[redis-internals]].

---

## The design

**Placement.** The limiter runs at the [[api-gateway]], so there is one enforcement point instead of the same logic copied into every service.

**Algorithm.** Token bucket. It allows short bursts, which real clients produce, and it stores a constant amount of data per user, see [[hardening]].

**Topology.** Redis Cluster, sharded by user id. Writes go to primaries. Replicas are for failover, not for reads, since a stale replica read would let a user over spend.

**Data model.** One hash per limited key, holding `tokens` and `last_refill_ts`, with the refill maths in [[redis-use-cases]].

```text
key:    rate_limit:user:{user_id}
fields: tokens (float), last_refill_ts (epoch ms)
```

**Atomicity.** Refill and consume run inside one Lua script.
A script executes atomically on its shard, so no other client's commands interleave with it.
That gives you correctness with a single network call and no lock.

> [!warning] Do not reach for a lock here
> A lock adds a round trip and creates contention on exactly the keys that are already hottest. The Lua script is one command from Redis's point of view, which is why it is the standard answer for a hot path.

---

## When Redis is not there

Rate limiting protects the system, but it is not the business function.
So the policy is to fail open:

| Situation | Behaviour |
| --- | --- |
| Redis slow | allow the request, alert |
| Redis down | allow the request, alert |
| Long outage | fall back to a rough in memory limit per instance |
| Redis back | resume the normal check |

Failing closed would turn a cache outage into a full outage, which is a worse trade for everything except money and quota enforcement.

---

## Extending it to IP as well as user

Same script, two keys:

```text
rate_limit:user:{user_id}
rate_limit:ip:{ip}
```

Reject if either bucket is empty.
The user key stops one account hammering the API, and the IP key stops one machine cycling through accounts.
Limiting on IP alone is the version that fails, since a whole office shares one address, see [[redis-use-cases]].

---

## The shape of it

```text
Client
  |
API Gateway  (rate limiter, runs the Lua script)
  |
Redis Cluster  (token bucket per user)
  |
Services
```

> [!tip] The one liner
> Redis Cluster gives us scale and Lua gives us atomic token bucket updates, because replicas do not solve concurrency.

---

## Self check before you call this done

- Why replicas do not fix a race.
- Why Lua beats a lock on the hot path.
- Which fields exist per user, exactly.
- What happens when Redis goes down.

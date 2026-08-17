# Dynamic Configuration Management

> [!tldr]
> A sidecar is just a background file downloader in the same pod. That one reframing makes the whole architecture click.

---

## The problem

A company runs 10,000 pods globally. An external AI provider starts throttling requests, and you need to instantly change `api_timeout_ms` from 2000 to 8000 and disable a heavy feature flag across the entire infrastructure.

**The naive approaches.**

**Redeploy.** Changing the environment variable and redeploying 10,000 pods takes 45 minutes. The system bleeds money throughout.

**Database polling.** Put the config in a database and have 10,000 pods run a `setInterval` querying every second. You just generated 10,000 [[qps|QPS]] of useless read traffic, effectively attacking your own database.

**The objective.** Build a push based configuration service. An engineer updates a JSON payload in a UI, and that payload streams into the local RAM of all 10,000 pods globally in under 5 seconds, with guaranteed fallback if the network drops.

---

## Functional requirements

**Mutate.** DevOps engineers create, update and version JSON configuration payloads.

**Boot up.** When a new pod spins up, it must download its latest configuration before accepting traffic.

**Stream.** When a config changes, push the delta to all live pods.

**Audit.** Maintain a strict historical ledger of who changed what and when, for compliance and rollback.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | one write triggers 10,000 simultaneous reads. The read to write ratio is astronomically high |
| Performance | end to end propagation under 5 seconds, local evaluation under 1 microsecond with zero network hops on the critical path |
| Availability against consistency | absolute availability. If the config service crashes, the 10,000 pods must not crash. They continue with their last known good state from RAM |
| Concurrency | safe atomic transitions in memory, preventing a pod reading a half updated config object |
| Edge cases | the poison pill config that crashes the app on propagation, and split brain where a pod silently disconnects and misses the update |

---

## The architecture

```text
================= PHASE 1: CONTROL PLANE (WRITES) ======================

      +-------------------------------------------+
      |          DEVOPS PORTAL (React Web)        |
      +---------------------+---------------------+
                            | 1. PUT /v1/configs/ai-agent-svc
                            v
      +-------------------------------------------+
      |          CONFIG ADMIN API (Node.js)       |
      |   (Validates JSON schema, creates audit)  |
      +------+------------------------------+-----+
             |                              |
 2. Save DB  |                              | 3. Publish event (pub/sub)
             v                              v
  +-------------------+          +---------------------------------+
  | MONGODB CLUSTER   |          |         REDIS CLUSTER           |
  | (Source of Truth) |          |  Channel: config.ai-agent-svc   |
  +-------------------+          +----------------+----------------+
                                                  |
=================== PHASE 2: DATA PLANE (STREAMING) =====================
                                                  | 4. Instantly fan out
                                                  v
  +------------------------------------------------------------------+
  |                   CONFIG STREAMING FLEET (Go / Node.js)          |
  |   (Stateless servers holding thousands of idle TCP connections)  |
  +------------------------------------------------------------------+
  |    Stream Node 1     |    Stream Node 2     |   Stream Node N    |
  +-------+--------------+--------+-------------+-------+------------+
          |                       |                     |
          | 5. Push JSON via Server-Sent Events (SSE)   |
          v                       v                     v
=============== PHASE 3: KUBERNETES EDGE (THE PODS) ==================

  +--------------------------------------------------------------+
  | AI-AGENT-SVC KUBERNETES POD                                  |
  |                                                              |
  |  +------------------+               +------------------+     |
  |  | CONFIG SIDECAR   |<--6. HTTP/SSE-| MAIN NODE.JS APP |     |
  |  | (Envoy or a      |---7. Update-->| (Business logic) |     |
  |  |  custom agent)   |   RAM         +------------------+     |
  |  |                  |                                        |
  |  | Holds fallback   |                                        |
  |  | JSON on disk.    |                                        |
  |  +------------------+                                        |
  +--------------------------------------------------------------+
```

---

## Boot up, the pull

1. A new pod spins up due to auto scaling.
2. The config sidecar boots first and makes a synchronous `GET /v1/configs/ai-agent-svc/latest` to the streaming fleet.
3. The fleet fetches the latest config from a Redis cache or MongoDB, returns it, and keeps the HTTP connection open, upgrading it to server sent events.
4. The sidecar saves the JSON to local disk for disaster recovery and passes it to the main app's RAM. The app binds to its port and begins serving traffic.

---

## The global push, the fan out

1. DevOps changes `api_timeout` to 8000.
2. The admin API saves version 45 to MongoDB and publishes the payload to Redis pub/sub on `config.ai-agent-svc`.
3. All 50 nodes in the streaming fleet are subscribed to that channel and receive the payload instantly in memory.
4. Each stream node loops through its active SSE connections, roughly 200 per node, and pushes the JSON patch down the wire.
5. The sidecar receives the patch, updates local disk, and atomically hot reloads the RAM configuration of the main app. Total time roughly 200 ms.

---

## API design

### Control plane: update configuration

**PUT** `/v1/configs/services/ai-agent-svc`

**Headers.** `Authorization: Bearer <Admin_JWT>`, `Content-Type: application/json`

```json
{
  "version_message": "Emergency timeout increase for provider throttling",
  "config_data": {
    "api_timeout_ms": 8000,
    "heavy_feature_enabled": false,
    "retry_count": 5
  }
}
```

### Data plane: stream configuration

**GET** `/v1/configs/stream/ai-agent-svc`

| Header | Purpose |
| --- | --- |
| `Authorization: Bearer <Service_Token>` | |
| `Accept: text/event-stream` | the crucial header initiating the SSE long lived connection |
| `If-None-Match: "v44"` | ETag caching, telling the server "I already have v44, only send data if there is a v45" |

```text
HTTP/1.1 200 OK
Content-Type: text/event-stream

event: update
data: {"version": "v45", "config_data": {"api_timeout_ms": 8000, ...}}
```

---

## Why MongoDB

Configurations are fundamentally unstructured, nested and constantly evolving JSON documents. With PostgreSQL you are forced to dump the config into a `JSONB` column anyway, losing the strict schema benefits of SQL.

MongoDB lets us store native JSON, validate it against JSON Schema at the database level, and query inside nested properties when needed.

**Collection `config_history`, the immutable ledger.** Append only, never updated, which guarantees a perfect audit trail and instant rollback.

| Field | Notes |
| --- | --- |
| `_id` | ObjectId, primary key |
| `service_name` | string, indexed |
| `version` | integer |
| `config_data` | document |
| `updated_by` | string |
| `created_at` | date |

Compound index: `{ service_name: 1, version: -1 }`, allowing a fast fetch of the latest version.

**Collection `active_configs`, the materialized view.** Exactly one row per service, optimised for fast reads: `service_name` as primary key, `current_version` integer, `config_hash` as an MD5 of the payload used for ETag matching, and `config_data`.

---

## Why Redis pub/sub instead of Kafka

You can use Kafka, but it is the wrong tool for this job.

**Kafka is for persistence.** It writes to disk, designed so a consumer offline for 3 hours can wake up and read historical messages.

**Redis pub/sub is for ephemeral speed.** It is purely in RAM, with sub millisecond latency.

**The deciding factor.** Configuration updates are fire and forget state changes, not a historical ledger of events. If a pod is offline when the config changes, it does not need to read a queue to see the timeout went 2s to 4s to 8s. It just needs to wake up and ask "what is the absolute latest version right now?"

---

## Why not connect all 10,000 pods directly to Redis

This is the most important question. Redis is incredibly fast but single threaded, processing one command at a time.

**Direct to Redis.** You have 10,000 open TCP connections. A minor network blip disconnects all of them, and they instantly try to reconnect in the same millisecond. Redis is slammed with 10,000 TCP handshakes on a single thread, CPU spikes to 100 percent, Redis freezes, and your entire configuration system goes offline.

**With the streaming fleet in between.** Put 50 cheap servers between them. Only those 50 connect to Redis, which handles 50 connections effortlessly. The 10,000 pods connect to the 50 streaming servers, 200 connections each, which any modern runtime handles in its sleep. If the network blips, the pods hammer the streaming servers, which absorb the shock and completely protect the fragile single threaded Redis.

---

## Do all 10,000 pods share one database?

Yes, there is one MongoDB, but the 10,000 pods never touch it.

If 10,000 pods query MongoDB every 10 seconds to check for new configs, that is 1,000 QPS of pure junk traffic, wasting thousands of dollars on database infrastructure just to check whether a JSON file changed.

The admin API talks to MongoDB to save the config. The 10,000 pods talk to the streaming fleet. The fleet holds the config in local RAM, so the pods get the config without a single database query.

---

## The sidecar pattern against an embedded SDK

**The dilemma.** How does the main app get the config? We could install a config SDK directly into the app code.

**The trap of SDKs.** If the SDK handles the SSE connection and the connection drops, it runs complex reconnection and backoff logic on the event loop, stealing CPU cycles from actual business logic. And if the company builds a new service in Python or Go, the entire complex SDK must be rewritten from scratch.

**The solution.** Deploy a lightweight container, written in Go or Rust for zero memory overhead, in the exact same Kubernetes pod as the app. The sidecar handles the complex SSE connections, retries and disk writes. The app simply reads a local file or queries localhost, at zero latency. That makes the configuration system fully language agnostic.

### What actually happens in each case

A pod is just a logical wrapper. You can put two containers inside one pod, sharing the same localhost network and the same disk volume. Container 1 is your app, container 2 is a tiny script, the sidecar.

**Without a sidecar.** You write the SSE logic directly inside your app. Your app is busy serving a heavy request when the config connection drops. The library initiates a complex exponential backoff loop, and that background network logic consumes CPU cycles on your main thread, slowing down the user's request. Worse, a bug in your config fetching logic crashes the process, taking down the business API with it.

**With a sidecar.** The sidecar opens the SSE connection and saves new configs to a shared local file, `/shared/config.json`. Your app just uses `fs.watch('/shared/config.json')` and reads it into RAM when it changes.

The result is that the app knows nothing about networks, SSE or retries, and its event loop is fully dedicated to serving users. If the sidecar crashes it does not affect the app at all, which keeps using the last known `config.json` on disk.

---

## The split brain network drop

**The scenario.** A load balancer drops the TCP connection to a sidecar, but the sidecar does not realise it, a half open TCP connection. It silently misses the v45 push and is now running stale config.

**The solution, state reconciliation.** SSE pushes are inherently fire and forget. To guarantee eventual consistency, the sidecar runs a background reconciliation loop. Every 60 seconds it executes an HTTP `HEAD /v1/configs/ai-agent-svc/latest`, and the fleet returns only headers, for example `ETag: "v45"`. The sidecar compares that with its local RAM at v44, detects the desynchronisation, and re downloads the full payload.

---

## Follow up questions

### The poison pill config

**Q.** You pushed v45 to 10,000 pods, but it contained a typo, a string `"8000"` instead of the integer, which crashes the agent instantly. Because your push system is so fast, you brought down the entire company globally in 5 seconds. How do you prevent this?

**A.** Phased rollouts plus automated health checks. Instead of pushing to 10,000 pods instantly, the streaming fleet looks at the Kubernetes labels and pushes to exactly 10 pods, the canary group. The control plane waits 60 seconds and queries the observability platform for the 5xx error rate of those 10 pods. If it spikes, the control plane aborts the rollout and pushes a rollback to v44. If healthy, it proceeds to 10 percent, then 50, then 100.

> [!warning] Instant global fan out is an anti pattern for configuration.

### Everything is down and a pod restarts

**Q.** The streaming fleet is down, MongoDB is dead, and at that moment a pod crashes and Kubernetes restarts it. How does it boot?

**A.** Absolute availability dictates the pod must survive. That is why the sidecar writes the config to a persistent local volume on every successful sync. If the pod restarts and the network is dead, the sidecar attempts the network call, times out, and falls back to reading `config_backup.json` from disk. It loads the stale config into RAM and lets the app boot. Stale configuration is infinitely better than a complete outage.

### The thundering herd of reconnections

**Q.** If 10,000 sidecars reconnect simultaneously after a brief outage, they hit the fleet in the same millisecond and overwhelm the Redis cache. How do you protect it?

**A.** Jitter in the reconnection logic. A disconnected sidecar does not reconnect instantly. It uses exponential backoff with randomised jitter, `Wait Time = Base * 2^attempt + Random(0, 1000ms)`, smearing 10,000 reconnections across a 30 second window.

Furthermore, the streaming fleet uses an in memory LRU cache with a 1 second [[ttl|TTL]]. The first sidecar request fetches from Redis, and the other 9,999 requests in that second are served from the streaming node's local memory, completely shielding Redis.

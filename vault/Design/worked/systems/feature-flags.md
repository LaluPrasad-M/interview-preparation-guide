# Distributed Feature Flag Service

> [!tldr]
> Truth lives in a central database, but evaluation happens in the RAM of each app server. The kill switch has to reach every server's memory in under 200 ms.

---

## The problem

A company wants to roll out a new checkout UI to exactly 15 percent of users in Canada without deploying new code. If it crashes, a product manager needs a kill switch that reverts it to 0 percent instantly.

The application calls `if (flags.isEnabled("new_checkout", user))` on every single web request. We cannot make a network call for this, or the application grinds to a halt.

**The objective.** The source of truth lives in a centralised database, but flag evaluation happens locally in the RAM of the application servers. When a PM clicks the kill switch, the update propagates globally to all servers' RAM in under 200 milliseconds.

---

## Functional requirements

**Management.** PMs can create, update and delete flags.

**Targeting.** Flags support boolean toggles, percentage rollouts, and user attribute targeting such as country equals CA.

**Evaluation.** The SDK evaluates flags instantly for a given user context.

**Propagation.** Updates stream to all connected SDKs in real time.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | writes are very low, around 1,000 flag changes per day. Reads are insanely high, billions per second globally |
| Performance | local evaluation under 1 microsecond, global propagation under 200 milliseconds |
| Availability against consistency | availability is absolute. If the backend explodes, client applications must not crash. They continue evaluating using their last known good state |
| Concurrency | percentage rollouts must be perfectly deterministic. If John is in the 15 percent group today, he must be tomorrow |
| Edge cases | hundreds of thousands of open connections causing connection exhaustion, and SDK boot up times |

---

## The architecture

```text
======================= PHASE 1: MANAGEMENT AND STORAGE ==========================

      +-------------------------------------------+
      |          ADMIN PORTAL (React Web)         |
      |        (PM clicks "Enable Flag")          |
      +---------------------+---------------------+
                            | 1. Sync HTTPS: PUT /v1/flags/new_checkout
                            v
      +-------------------------------------------+
      |          FLAG MANAGEMENT API (CRUD)       |
      +------+------------------------------+-----+
             |                              | 2. Save State
 3. Publish  |                              v
 Event       v                    +--------------------+
  +--------------------+          | POSTGRESQL         |
  | REDIS PUB/SUB or   |          | (Source of Truth)  |
  | KAFKA TOPIC        |          +--------------------+
  +----------+---------+
             | 4. Fan out to all streaming servers
             v
======================= PHASE 2: REAL-TIME STREAMING ==========================

  +--------------------------------------------------------------+
  |                   FLAG STREAMING FLEET                       |
  |     (Highly optimised Go / Node.js servers holding TCP)      |
  +----------------------+----------------------+----------------+
  |    Stream Node A     |    Stream Node B     | Stream Node C  |
  +-------+-----+--------+-------+------+-------+--------+-------+
          |     |                |      |                |
          |  5. Push JSON via Server-Sent Events (SSE)   |
          v     v                v      v                v
======================= PHASE 3: ZERO-LATENCY EVALUATION =======================

  +--------------+  +--------------+  +--------------+  +--------------+
  | Main App Pod |  | Main App Pod |  | Main App Pod |  | Main App Pod |
  +--------------+  +--------------+  +--------------+  +--------------+
  | FEATURE FLAG |  | FEATURE FLAG |  | FEATURE FLAG |  | FEATURE FLAG |
  | SDK (In RAM) |  | SDK (In RAM) |  | SDK (In RAM) |  | SDK (In RAM) |
  +------+-------+  +--------------+  +--------------+  +--------------+
         | 6. Local memory evaluation (< 1 microsecond)
         v
    if (sdk.isMatch("new_checkout", { user_id: "123", country: "CA" })) { ... }
```

---

## The data flow

### Phase A: SDK initialisation

**1. The connection.** When the main application boots, the embedded SDK opens an HTTP connection to the streaming fleet.

**2. The sync.** The SDK requests all currently active flags for its environment. The streaming server fetches this from a Redis cache and sends the full JSON payload.

**3. The persistent connection.** The SDK does not close the connection. It keeps it open using server sent events, and stores the rules in a concurrent hash map in local RAM.

### Phase B: flag evaluation, the read path

**4. The zero hop check.** The application calls `sdk.evaluate("dark_mode", user_context)`. The SDK makes no HTTP call, it reads local RAM.

**5. The rule engine.** It evaluates the rules locally, for example checking whether the user's country matches, and returns true or false in microseconds.

### Phase C: the kill switch, the write path

**6. The update.** A PM disables `dark_mode` in the UI, and the management API updates Postgres.

**7. Internal pub/sub.** The API publishes `{ "flag_key": "dark_mode", "status": false, "version": 5 }` to a Redis pub/sub channel or Kafka topic.

**8. The global push.** All 500 streaming servers are subscribed to that channel and instantly receive the message.

**9. The fan out.** Each streaming server looks at its thousands of open SSE connections and pushes the tiny JSON patch down the wire.

**10. The RAM update.** The SDK receives the SSE event and safely overwrites `dark_mode` in its local map. The app is updated globally in under 200 ms.

---

## Why server sent events

**Polling.** Asking the server every 10 seconds creates massive unnecessary traffic and delays updates by up to 10 seconds.

**WebSockets.** These are bidirectional, but SDKs never need to send data back to the streaming server. Writes go through the management API.

**SSE.** This is a unidirectional stream over standard HTTP/1.1, perfect for pushing server state to a client efficiently. See [[websockets-and-sse]].

**Endpoint.** `GET /v1/stream/flags?env=production`

**Headers.** `Authorization: Bearer <SDK_KEY>` and `Accept: text/event-stream`, which is crucial for SSE.

The server responds `200 OK` but leaves the connection open. As updates happen it pushes:

```text
event: patch
data: {"key": "new_checkout", "enabled": false, "version": 5}

event: patch
data: {"key": "dark_mode", "rollout_percentage": 20}
```

---

## Database and rules design

The database must store the rules, not just a boolean.

**Table `feature_flags`.**

| Column | Notes |
| --- | --- |
| `id` | UUID, primary key |
| `key` | VARCHAR, unique index, for example `new_checkout` |
| `environment` | VARCHAR, for example `production` |
| `version` | INT, used for optimistic locking so PMs do not overwrite each other |
| `rules` | JSONB, the payload sent to the SDKs |

The JSONB rule payload is exactly what the SDK holds in RAM:

```json
{
  "key": "new_checkout",
  "enabled": true,
  "rules": [
    {
      "attribute": "country",
      "operator": "IN",
      "values": ["CA", "US"],
      "serve": true
    },
    {
      "attribute": "user_id",
      "operator": "PERCENTAGE_ROLLOUT",
      "percentage": 15,
      "serve": true
    }
  ],
  "default_serve": false
}
```

---

## Deterministic percentage rollouts

**The trap.** The PM wants 15 percent of users to see the new checkout. A junior engineer uses `Math.random() < 0.15` in the SDK. If John refreshes the page, the random number changes and the UI vanishes.

**The solution.** Rollouts must be sticky. The SDK uses a fast deterministic hash such as MurmurHash3.

```text
hash = MurmurHash(user_id + flag_key)
bucket = hash % 100
if (bucket < 15) return true;
```

Because John's `user_id` never changes, the hash never changes. He always falls into the same bucket, no matter how many times he refreshes. Zero database lookups required.

---

## Connection exhaustion

**The problem.** If your company has 50,000 microservice pods, your streaming fleet must hold 50,000 open TCP connections. Linux servers typically max out at 65,000 ephemeral ports.

**The solution.** Horizontally scale the streaming fleet behind an L4 network load balancer, and aggressively tune the Linux kernel, `ulimit -n` and `tcp_tw_reuse`, on the streaming servers to hold hundreds of thousands of idle connections.

We trade infrastructure cost, running lots of streaming servers, for instant real time updates.

---

## When the SDK disconnects

**The scenario.** A network blip drops the SSE connection, so the SDK misses a kill switch event.

**The defence, fallback and reconnect.** The SDK continues evaluating using its last known RAM state, choosing availability over consistency. It uses exponential backoff to reconnect. As a last resort we implement an async local disk cache, so if the pod reboots while the streaming server is down it reads flags from local disk and survives the total outage.

---

## Last known good state against default state

If a PM turned a big feature on yesterday, and today your pod restarts due to a memory limit while the flag service happens to be down, falling back to a hardcoded `default_states.json` instantly turns that feature off. Users suddenly lose access to something they were just using.

Last known good state is vastly superior to a default state. Three industry standard strategies, simplest first.

### Strategy 1: local disk persistence, the standard SDK approach

Every time the SDK receives an event and updates RAM, it also asynchronously overwrites a file on local disk, for example `/var/lib/flags/last_known_rules.json`.

**The cold start.** On restart the SDK tries the central flag service. On a `503`, it reads the local file and loads those rules back into RAM.

**The Kubernetes trap.** If the pod is destroyed and rescheduled onto a different worker node, the local disk is wiped. To make this work you must mount a persistent volume, which adds deployment complexity.

### Strategy 2: Kafka log compaction, the streaming approach

If you already use Kafka to push updates, Kafka itself becomes the fallback database.

Configure the `Flag_Updates` topic to use log compaction, telling Kafka never to delete based on time and to keep the most recent message for every unique flag key. See [[log-compaction]].

**The cold start.** The service boots while the flag service is down. It ignores the flag service entirely, connects to the Kafka topic and reads from offset 0. Because the topic is compacted, it instantly downloads the exact last known good state for every flag and rebuilds its RAM.

**The trade off.** You have shifted the single point of failure. If both the flag service and Kafka are down, you are blind.

### Strategy 3: the edge cache, Redis fallback

The central flag service writes rules to both PostgreSQL and a geographically distributed Redis cluster.

**The cold start.** The service boots, calls the flag service API and fails, then calls the Redis fallback cluster and succeeds.

**The trade off.** You pay for a large Redis cluster used only during emergencies. And if the flag service dies halfway through a write, the primary DB and the cache can hold conflicting rules, a split brain.

### The verdict

At scale, combine strategies 1 and 2. The service tries the central API, falls back to replaying the compacted Kafka topic, and if the network is completely severed reads from a local disk file mounted via a persistent volume.

That guarantees a user never randomly loses access to a feature just because an internal service rebooted.

---

## Follow up questions

### Mobile apps

**Q.** This works for backend microservices. What about mobile? Mobile networks are flaky and we cannot keep 50 million SSE connections open to every phone on earth.

**A.** The embedded SDK pattern is strictly for backend servers. For mobile and frontend, use the proxy API pattern. We do not stream rules to the phone, nor trust the phone's clock or hashing. The app makes a standard `GET /v1/evaluate?user_id=123` call at boot. A fleet of edge API servers, which run the embedded SDK locally, evaluate the flags on behalf of the mobile user and return static JSON: `{ "dark_mode": true, "new_checkout": false }`. The app caches that for the session.

### A deleted flag still referenced in code

**Q.** What if a developer deletes a flag from the portal but old application code still calls `sdk.evaluate('deleted_flag')`? Will the app crash?

**A.** Flag evaluation must be strictly safe and non blocking. The SDK signature always requires a default fallback provided in the code: `sdk.evaluate("deleted_flag", user, false)`. If the SDK cannot find the key in RAM it intercepts the exception, logs a warning, and gracefully returns the developer's fallback. The app never crashes.

### A hundred thousand flags

**Q.** With 100,000 flags, the JSON payload downloaded on boot will be massive. How do we prevent OOM crashes?

**A.** In a mature system you rarely need 100k active flags. The real solution is lifecycle management. Flags are temporary technical debt. We track in the SDKs when a flag evaluates to 100 percent true for 30 consecutive days, automatically tag it stale, and open tickets forcing developers to rip it out of the code and delete it, keeping the active rule set lean and fast.

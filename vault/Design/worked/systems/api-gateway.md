# Enterprise API Gateway

> [!tldr]
> This is the absolute boundary between the chaotic public internet and your trusted internal network. It must add under 5 ms, because it sits on the critical path of every single request.

---

## The problem

Your company has grown to 50 or more backend microservices. The mobile app needs data from 4 of them to render the home screen.

If the app makes 4 separate HTTP requests to 4 subdomains over cellular networks, it feels incredibly slow.

If every microservice is exposed to the public internet, handles HTTPS certificates and validates JWTs, you have duplicated massive security vulnerabilities across 50 codebases.

**The objective.** Build a single highly available reverse proxy that handles SSL termination, mathematical JWT validation, rate limiting, and routing to the correct internal microservice, adding under 5 ms of latency.

---

## Functional requirements

**Routing.** Route `/v1/billing/*` to the billing service IP, `/v1/search/*` to search.

**Security offloading.** Terminate SSL/TLS certificates and validate JWT signatures locally.

**Mutation.** Strip security headers from the outside, and inject internal trusted headers such as `X-User-ID: 123`.

**Resilience.** Execute circuit breaking and strict timeouts if an internal microservice goes down.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | the highest traffic component in the company, 100 percent of external traffic, target above 1,000,000 [[qps|QPS]] |
| Performance | under 5 ms of overhead, which rules out slow languages for the gateway layer |
| Availability against consistency | absolute availability. If the gateway is down, revenue is zero. A massively horizontally scaled cluster behind an L4 load balancer |
| Concurrency | hundreds of thousands of simultaneous open TCP connections, the C10K and C100K problem |
| Edge cases | backend service timeouts causing thread starvation, and dynamic config reloads without dropping active connections |

---

## The architecture

```text
======================= PUBLIC INTERNET (UNTRUSTED) ========================

      +-------------------------------------------+
      |         CLIENT APPS (Mobile / Web)        |
      +---------------------+---------------------+
                            | 1. DNS Resolution -> Anycast IP
                            | 2. TCP/TLS Connection (HTTPS)
                            v
      +-------------------------------------------+
      |       L4 NETWORK LOAD BALANCER            |
      |   (Pure TCP pass-through, no SSL config)  |
      +---------------------+---------------------+
                            | 3. Forward TCP Packets
                            v
======================= THE GATEWAY FLEET (DMZ BOUNDARY) ===================

  +--------------------------------------------------------------+
  |                 API GATEWAY DATA PLANE (Kong / Envoy)        |
  |     (Written in C/C++/Rust. Event loop, non-blocking I/O)    |
  +----------------------+----------------------+----------------+
  |     Gateway Node 1   |     Gateway Node 2   | Gateway Node N |
  +-------+------+-------+-------+------+-------+--------+-------+
          |      |               |      |                |
  4. Sync |      | 5. TCP        |      | 6. TCP         |
   Memory |      v               |      v                |
   (JWT)  |  +--------------+    |  +--------------+     |
          |  | REDIS CLUSTER|    |  | SERVICE MESH |     |
          |  |(Rate Limiter)|    |  |(Consul / K8s)|     |
          |  +--------------+    |  +--------------+     |
          v                      v                       v
======================= PRIVATE NETWORK (TRUSTED) =========================

    7. Internal HTTP/gRPC (Injected Header: X-User-ID: 123)

  +--------------+       +--------------+        +--------------+
  | BILLING PODS |       | SEARCH PODS  |        | BOOKING PODS |
  +--------------+       +--------------+        +--------------+
```

---

## The request lifecycle, step by step

**1. SSL termination at layer 7.** The TCP connection from the mobile app hits gateway node 1, which holds the actual `.pem` certificate and decrypts the HTTPS traffic to plaintext HTTP. The internal network then uses fast unencrypted HTTP or [[mutual-tls|mTLS]].

**2. Auth validation, filter chain step 1.** Node 1 intercepts the `Authorization: Bearer <JWT>` header, checks its local RAM for the auth service public key from `jwks.json`, and mathematically verifies the signature in under 0.1 ms. See [[jwt]].

**3. Rate limiting, filter chain step 2.** Node 1 fires a rapid Lua script to the Redis cluster to check the user's token bucket.

**4. Header mutation.** Node 1 strips the JWT, so internal services cannot accidentally leak it, and injects `X-User-ID` and `X-Correlation-ID`, a UUID used for distributed tracing.

**5. Service discovery.** The user requested `/v1/search`, so node 1 asks the local [[service-mesh|service mesh]] sidecar, Kubernetes DNS or Consul, for the internal IP of a healthy search pod.

**6. Reverse proxying.** Node 1 opens a keep alive HTTP connection to the search pod, forwards the modified request, buffers the response, and streams it back to the client.

---

## Gateway configuration

API gateways are usually configured declaratively via a control plane, not in code.

```yaml
routes:
  - name: search-service-route
    match:
      prefix: "/v1/search"
    plugins:
      - name: jwt-validator
        config:
          jwks_uri: "http://auth-service/.well-known/jwks.json"
      - name: rate-limiter
        config:
          limit: 100
          window_sec: 60
    route:
      cluster: internal-search-cluster
      strip_path: false
      append_headers:
        X-Gateway-Enforced: true
```

---

## Control plane against data plane

This is a critical distinction. Gateways have two physical halves.

**The data plane, the nodes.** These are the C or C++ servers doing the actual proxying. They have no database. They hold all configuration in RAM to ensure zero disk I/O latency.

**The control plane, the admin API.** This is a separate internal service used by DevOps to manage routes, backed by PostgreSQL.

**Table `gateway_routes`.**

| Column | Type | Holds |
| --- | --- | --- |
| `id` | UUID, PK | |
| `path_prefix` | VARCHAR, unique | for example `/v1/billing` |
| `upstream_url` | VARCHAR | for example `http://billing-svc:8080` |
| `active_plugins` | JSONB | for example `["jwt", "rate-limit"]` |
| `version_hash` | VARCHAR | crucial for cache invalidation |

**How the data plane gets updates.** When DevOps adds a route to Postgres, the control plane pushes the new `version_hash` via gRPC to all 500 data plane nodes, which instantly refresh their RAM.

---

## Trade offs

### C or Rust against Java for the gateway layer

**The trap.** "We are a Java company, so we will use Netflix Zuul or Spring Cloud Gateway."

**The reality.** Java uses garbage collection. Under extreme loads above 100k QPS, JVM GC pauses can freeze the gateway for 200 to 500 ms. In a gateway, a 500 ms freeze causes cascading TCP timeouts across the entire network.

**The decision.** Use gateways written in C, C++ or Rust: Envoy, Nginx, Kong. They use manual memory management and an asynchronous event loop such as epoll or kqueue, handling 100,000 concurrent TCP connections on a single thread with no GC spikes.

### Single global gateway against backend for frontend

**The dilemma.** If iOS, Android and web teams all force routing changes into one monolithic global gateway, the config becomes a 50,000 line YAML file that breaks constantly.

**The solution.** Deploy an edge gateway purely for SSL and security, which routes to team specific BFF gateways such as an iOS gateway and a web gateway. The iOS team mutates headers and aggregates endpoints on their own gateway without breaking the web team.

---

## Follow up questions

### The gateway crashed because one service was slow

**Q.** Our search service takes 30 seconds to respond. Suddenly the API gateway crashes, bringing down billing and booking too. Why, and how do we fix it?

**A.** This is classic thread exhaustion and connection pool starvation. If search takes 30 seconds, the gateway holds open a TCP connection to the client and another to search for 30 seconds. If 50,000 users query search, the gateway maxes out its allowed file descriptors and ports, and physically cannot accept new connections for billing or booking.

**The fix.** Strict timeouts, for example 2 seconds maximum, plus the circuit breaker pattern. If the gateway sees a 50 percent timeout rate to search, it trips the breaker to open and instantly returns HTTP 503 to any new search request in 1 millisecond, freeing the thread pool so billing and booking traffic continues.

### Reloading config without dropping connections

**Q.** How do you reload configuration without dropping the 500,000 active TCP streams currently downloading data?

**A.** A zero downtime hot reload, like Envoy's xDS protocol or Nginx's master and worker model. The control plane sends the new configuration. The master process spawns a brand new set of worker threads loaded with it. All new incoming requests route to the new workers. The old workers enter a draining state, finish streaming to their existing clients, and once their connection count hits 0 they gracefully terminate. Zero dropped packets.

### Aggregating multiple services into one call

**Q.** The mobile app needs billing, profile and orders to render a dashboard, and 3 API calls over 3G is slow. Can the gateway help?

**A.** Yes, through GraphQL federation or API composition at the gateway layer. The app makes exactly one HTTP POST. The gateway parses it, executes three parallel internal gRPC calls over the fast internal LAN, aggregates the JSON responses into a single payload, and sends one unified response back. That drastically reduces cellular round trips.

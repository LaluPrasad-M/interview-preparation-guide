# Where To Look By Component

> [!tldr]
> One table per component, each row a signal you can see on a dashboard, what usually causes it, and the next place to look. [[incident-triage]] is the process, this is the lookup table you use inside it.

---

## API and Node service

| Signal | Likely cause | Check next |
| --- | --- | --- |
| CPU up, latency up | heavy JSON parsing, crypto, a bad regex, a loop that does not end | CPU profile, event loop lag, see [[node-profiling]] |
| CPU down, latency up | the process is waiting, not working | traces, then the database, Redis, Kafka and external calls |
| Memory climbing steadily | a leak, something retained per request | heap snapshots, object retention |
| Memory jumping suddenly | large payloads or a cache filling up | heap dump, request body sizes |
| Event loop lag up, CPU up | CPU bound work on the main thread | flamegraph, see [[event-loop-lag]] |
| Event loop lag up, CPU down | GC pauses, synchronous I/O, or libuv thread pool saturation | GC trace, `fs` and `crypto` usage |
| Error rate up | a bad deploy or a failing dependency | logs, traces, recent releases |
| P99 up, average fine | tail latency on a subset of requests | compare a fast trace against a slow one |

---

## Database

| Signal | Likely cause | Check next |
| --- | --- | --- |
| CPU up | expensive queries, a missing index | slow query log, execution plans, see [[query-optimization]] |
| CPU down, latency up | lock contention or pool exhaustion | active sessions, lock waits, see [[read-lock-contention]] |
| Connections at max | connection pool exhaustion, often a leak | pool metrics, connections never released |
| Replica lag up | heavy writes, slow replication | replication status, see [[replication-lag]] |
| Disk I/O up | full table scans | query plans |
| Deadlocks up | transactions taking locks in different orders | deadlock log, see [[locking-strategies]] |
| Writes slow | locking, write ahead log pressure, storage limits | write latency metrics, see [[write-ahead-log]] |

**Where those numbers live in MySQL.** `performance_schema`, the slow query log, InnoDB metrics, and dashboards built on them such as PMM.
The five worth watching are lock waits, active transactions, replication lag, query latency and connection count.

---

## Kafka producer

| Signal | Likely cause | Check next |
| --- | --- | --- |
| Produce latency up | broker trouble or network | broker metrics |
| Retries up | a broker is unavailable | broker health, see [[in-sync-replicas]] |
| Throughput down | compression cost or a network bottleneck | producer metrics |
| Buffer full | producing faster than the brokers accept | broker throughput |

---

## Kafka consumer

| Signal | Likely cause | Check next |
| --- | --- | --- |
| Lag up, CPU and memory low | a [[poison-message]], a [[hot-key|hot partition]], or a slow downstream call | per partition lag breakdown |
| Lag up, CPU high | consumers genuinely overloaded | add consumers, up to the partition count |
| Lag up but concentrated in one partition | skew, the key distribution is uneven | partition distribution |
| Lag up right after a deploy | a bug in the new consumer | roll back first, investigate after |
| Rebalances happening constantly | crashes or scaling events, a [[rebalance-storm]] | group coordinator logs |
| Processing time per message up | the database or API the consumer calls got slower | traces |

More on the investigation order in [[lag-and-dead-letter-queues]].

---

## Redis

| Signal | Likely cause | Check next |
| --- | --- | --- |
| Memory up | the cache is growing without bound | biggest keys, `MEMORY USAGE` |
| Evictions up | memory limit reached | `maxmemory` and the eviction policy |
| CPU up | large scans or expensive Lua scripts | `SLOWLOG`, see [[redis-internals]] |
| Hit ratio down | the cache is being asked for things it never holds | access patterns, see [[caching-problems]] |
| Latency up | network, or a blocking command holding the single thread | `SLOWLOG` |

---

## External dependency

| Signal | Likely cause | Check next |
| --- | --- | --- |
| Latency up | the vendor is degraded | traces, vendor status page |
| Error rate up | rate limits or an outage on their side | their status page, your retry metrics |
| Timeouts up | network or vendor problem | retry metrics, see [[timeouts-and-circuit-breakers]] |
| Traffic normal but P99 up | partial degradation, some of their capacity is unhealthy | compare traces |

---

## Kubernetes and the infrastructure layer

| Signal | Likely cause | Check next |
| --- | --- | --- |
| Pod restarts up | crashes or [[out-of-memory-kill|OOMKilled]] | pod events |
| CPU throttling up | container CPU limit set too low | container limits |
| Pods pending | no node has room | scheduler events, cluster autoscaler |
| Errors right after a rollout | bad deploy | roll back, see [[kubernetes-basics]] |

**Where those numbers come from.** Kubernetes metrics, `node exporter` for the host, and `cAdvisor` for per container CPU, memory and network.

---

## Load balancer and gateway

| Signal | Likely cause | Check next |
| --- | --- | --- |
| 502 or 503 rising | backends unhealthy | service health checks, readiness probes |
| Latency up | backends slow, the balancer is just reporting it | traces |
| Traffic unevenly spread | balancing or [[sticky-session|sticky session]] configuration | per instance request distribution |
| Connection errors up | backend connection or socket exhaustion | pool metrics |

---

## The four patterns worth memorising

| Pattern | Read it as | Look at |
| --- | --- | --- |
| CPU low, memory low, latency up | waiting | database, Redis, Kafka, external APIs, lock contention, pool exhaustion |
| CPU up, latency up | computing | profiler, event loop lag, expensive queries |
| P99 up, average fine | tail latency | fast against slow traces, hot partitions, one tenant, one endpoint |
| Kafka lag up, CPU and memory low | blocked, not overloaded | per partition lag first, then poison message, hot partition, slow downstream, rebalances |

> [!tip] The line that separates two different incidents
> Kafka lag rising while consumer CPU stays low usually means the consumer is waiting rather than processing. The first question is whether the lag sits in one partition or spreads across all of them, because that separates a skew or blocking problem from a capacity problem.

---

## Correlating dashboards, a worked read

| Signal | What it showed |
| --- | --- |
| P99 latency | exploding |
| CPU | low |
| Database connection acquire wait | huge |
| Kafka lag | increasing |
| Retries | increasing |
| Event loop lag | rising |

Read together, that is connection starvation amplifying into queue growth, not a CPU problem and not a Kafka problem.
No single panel says that, which is the reason incidents are read across dashboards rather than from one.

> [!tip] Distributed systems are networks of queues
> Request queues, Kafka topics, database wait queues, thread pool queues, socket backlogs, retry queues, the event loop queue. A latency explosion almost always starts with one of them growing faster than it drains, so "which queue is growing" is a better first question than "which service is slow".

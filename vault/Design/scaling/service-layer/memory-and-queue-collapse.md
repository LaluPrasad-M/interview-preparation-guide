# Memory Leaks, Resource Exhaustion And Queue Collapse

> [!tldr]
> The slow death: memory that never comes back, pools that run dry, and a queue that stops draining.

Part of [[service-layer]].

---

## Stage 8: memory leaks, resource exhaustion and queue collapse

The central idea: resources are easy to acquire, resources are hard to release correctly.

Most engineers think failures happen because CPU hit 100 percent or a dependency crashed. Most production systems fail because resources accumulate faster than they are released.

> [!tip] The core realisation
> Systems usually die from accumulation, not explosion.

Memory grows slowly, the queue grows slowly, connections leak slowly, sockets accumulate slowly, consumers fall behind slowly, and then eventually the system becomes unusable.

### The universal failure pattern

```text
Acquire Resource
-> Retain Resource
-> Accumulate Resource
-> Exhaust Resource
-> System Collapse
```

The same pattern, different resource:

| Resource | The chain |
| --- | --- |
| Memory | allocate, retain objects, heap growth, GC pressure, [[out-of-memory-kill|OOM]] |
| Database connections | acquire, forget release, pool exhaustion, request blocking |
| Kafka | produce messages, consumer falls behind, lag grows, queue collapse |
| Sockets | open socket, forget cleanup, file descriptor exhaustion, network failures |

### Queue collapse

The most important system design equation:

```text
Arrival Rate > Processing Rate
```

When this holds, queue growth is eventually infinite.

**Example.** The system receives 20,000 messages per second while the consumer processes only 15,000, a difference of 5,000 per second. The queue grows forever. After one minute that is 300,000 extra messages; after ten minutes, 3 million.

Nothing crashed. Kafka is healthy, consumers are healthy, the database is healthy. But the business sees orders delayed by 30 to 45 minutes. That is queue collapse.

> [!warning] Kafka does not remove work
> Many engineers subconsciously think Kafka equals scalability. Kafka provides temporal decoupling, not infinite processing capacity. Kafka stores work; Kafka does not eliminate work.

### Memory leaks

The classic leak:

```js
const users = [];

app.get('/user', async (req, res) => {

  const user = await fetchUser();

  users.push(user);

  res.send(user);
});
```

Every request adds memory, memory never becomes eligible for cleanup, the heap grows forever, and eventually you get an OOM.

**Logical memory leaks** are much more common in production:

```js
const cache = new Map();

cache.set(id, user);
```

No [[ttl|TTL]], no eviction, no size limit. Looks harmless. Eventually the cache grows infinitely, which is effectively a memory leak with a nicer name.

> [!warning] Caches are often memory leaks
> A cache without a TTL, eviction, or capacity limits is a controlled memory leak. Interviewers love this observation.

### Resource exhaustion beyond memory

Resources include the heap, DB connections, Redis connections, Kafka consumers, threads, file descriptors and sockets. Any of them can become a bottleneck.

**Database connection leaks.**

```js
// Bad
const conn = await pool.connect();
await conn.query(...);
return result;

// Correct
const conn = await pool.connect();
try {
  return await conn.query(...);
} finally {
  conn.release();
}
```

Always release resources.

**Connection pool exhaustion.** The pool has 100 connections; if each request leaks one, eventually all 100 leak. New requests cannot obtain connections, latency rises, timeouts appear, and the system looks slow. The root cause is a resource leak.

**Socket exhaustion.** `axios.get(...)` creates connections that are never cleaned up properly, eventually thousands of sockets remain open, OS connection limits are reached, and new requests fail.

**File descriptor exhaustion.** The typical symptom is `EMFILE` and "too many open files". Root cause: open, forget close, accumulate, exhaust. The same stage 8 pattern.

### Connecting stages 7 and 8

Stage 7 taught that a slow dependency causes request retention, memory growth, GC pressure and event loop lag.

Stage 8 extends this. Suppose Kafka consumers fall behind and developers react with `consumer.poll(100000)`, huge batches. Now memory rises, GC pressure rises, event loop lag rises, the consumer slows further, and lag grows further. Another feedback loop, and everything learned earlier starts connecting.

### Latent failure

A system may appear healthy: Kafka up, consumers up, database up, API up. Yet users complain that orders are delayed by an hour, because the backlog exploded. That is a latent failure. The failure exists; the crash does not.

### Metrics to monitor

**For memory.** Heap used, heap total, GC duration, GC frequency.

**For queues.** Consumer lag, queue depth, oldest message age, processing rate, arrival rate.

**For connections.** Pool utilisation, wait time, active connections.

**For Node.js.** Event loop lag, open handles, pending promises, socket count.

These often reveal problems before CPU does.

### Common questions from this stage

What is queue collapse? Why can Kafka be healthy while users experience delays? What is consumer lag? What is the difference between a memory leak and memory retention? Why can caches become memory leaks? What is connection pool exhaustion? How would you debug resource exhaustion? Why does arrival rate greater than processing rate eventually cause failure? What metrics would you monitor for Kafka consumers? What is a latent failure?

> [!tip] The single most important sentence
> Most distributed systems fail because pressure accumulates faster than the system can dissipate it.

---


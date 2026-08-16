# Service Layer Failures, Stage by Stage

> [!tldr]
> Microservices distribute latency and failure across networks. The stages below trace how a healthy system degrades and what each defence actually protects.

---

## The biggest evolution

At the beginning, microservices look modular, clean, scalable and independently deployable:

```text
Client
-> API Gateway
-> Checkout Service
-> Payment Service
-> Inventory Service
-> Notification Service
```

Initially everything appears healthy. The deeper realisation across these stages is that microservices distribute latency and failure across networks, which is the foundation for latency amplification, retries, queue buildup, cascading failures and overload collapse.

---

## Stage 1: synchronous chains and latency amplification

Every service dependency is now a network dependency.

Earlier in monoliths a function call was cheap. Now every dependency means TCP plus serialisation plus queueing plus retries plus partial failure.

Even small service latencies accumulate across chains:

```text
Gateway           -> 20ms
User Service      -> 40ms
Coupon Service    -> 30ms
Inventory Service -> 50ms
Payment Service   -> 120ms
```

Suddenly you have 300ms or more of request latency, before retries, GC pauses, queueing and connection exhaustion. That is latency amplification.

### Pending promise accumulation

Suppose 20k requests per second arrive and the Payment Service latency is 5 seconds. You may now have 100k or more pending promises alive simultaneously, which creates heap growth, GC pauses, event loop lag and timeout amplification. One of the most common Node.js production failures.

**The realisation.** Microservices distribute latency instead of eliminating complexity, and synchronous dependency chains amplify pressure across systems.

---

## Stage 2: retry storms and cascading failures

> [!warning] Retries are traffic multipliers
> Weak engineers think retry equals resilience. Strong engineers understand retry equals amplified load.

### How a retry storm begins

The Payment Service slows from 100ms to 2 seconds while the Checkout timeout is 1 second, so retries begin.

The naive implementation looks resilient:

```js
while (retries > 0) {

  try {
    return await axios.post(
      "http://payment-service/pay",
      payload,
      { timeout: 1000 }
    );

  } catch (err) {
    retries--;
  }
}
```

It is actually dangerous, because retries generate new traffic.

**Retry amplification.** 10k requests per second entering the system, each retrying 3 times, means the downstream service suddenly receives 30k requests per second instead of 10k.

### The cascading failure chain

```text
DB slowdown
-> payment latency rises
-> retries begin
-> QPS amplifies
-> connection pools saturate
-> queues grow
-> memory pressure rises
-> GC pauses increase
-> more timeouts occur
-> more retries occur
```

### Recovery lag

Systems often remain unhealthy after the dependency recovers, because queues are still huge, retries still active, sockets still occupied and memory pressure still high.

### The fix: exponential backoff

Instead of immediate retries, `delay *= 2` spreads retries over time and reduces retry synchronisation spikes.

### Idempotency returns

Retries introduce duplicate execution risk, especially dangerous for payments, wallet deductions and inventory reservations.

```json
{
  "paymentId": "txn_123",
  "amount": 500
}
```

with database protection:

```sql
CREATE UNIQUE INDEX idx_payment_id
ON payments(payment_id);
```

This prevents duplicate charges during retries and is production critical.

**The realisation.** Distributed systems usually collapse through feedback loops, not hard crashes. Retries convert localised slowness into distributed overload.

---

## Stage 3: timeouts, backpressure and load shedding

A massive mindset transition. The junior mindset is "serve every request". The senior mindset is "survive overload".

**The core realisation.** Overloaded systems must intentionally reject work. This initially feels wrong emotionally, but it is exactly how resilient systems survive.

### No network call without a timeout

Dangerous:

```js
await axios.post(
  "http://payment-service/pay",
  payload
);
```

This may hang indefinitely, retain sockets, retain promises and accumulate memory. The production safe version:

```js
await axios.post(
  "http://payment-service/pay",
  payload,
  {
    timeout: 1000
  }
);
```

### Timeout ambiguity

The caller times out at 1 second but the downstream completes at 1.2 seconds. The caller thinks the request failed while the downstream already succeeded, creating uncertain distributed state.

This is exactly why idempotency, replay protection and distributed correctness keep reappearing.

### Backpressure

Systems intentionally slow intake, reject work, limit concurrency and protect downstream dependencies. This is survivability engineering.

**Unbounded concurrency is deadly.** This creates unbounded downstream pressure and is very dangerous during spikes:

```js
await Promise.all(
  orders.map(order =>
    processPayment(order)
  )
);
```

The production safe version uses concurrency limits:

```js
const pLimit = require('p-limit');

const limit = pLimit(10);

await Promise.all(
  orders.map(order =>
    limit(() => processPayment(order))
  )
);
```

Now a maximum of 10 concurrent downstream requests, which is admission control.

### Load shedding

The system intentionally rejects low priority, expensive or non critical traffic during overload.

During a flash sale: recommendations disabled, analytics delayed, notifications deferred, but checkout survives. That is prioritised degradation. Strong systems degrade selectively; weak systems collapse entirely.

### Latency budgets

Suppose the overall API SLO is 300ms. The budget is distributed:

```text
Gateway: 20ms
User Service: 30ms
Inventory: 50ms
Payment: 100ms
```

That becomes timeout budgeting, very important for large distributed systems.

**The realisation.** Healthy distributed systems survive overload by rejecting work intentionally. Unbounded acceptance is one of the fastest paths to distributed collapse.

---

## Stage 4: circuit breakers and bulkheads

Stages 1 to 3 were still fundamentally reactive. One major problem remained: why are healthy services still getting damaged by unhealthy services?

**The core realisation.** Failures should be isolated before they spread. Earlier stages taught how failures begin, how pressure propagates and how retries amplify. This stage teaches how to stop the propagation itself. Instead of recovering from failure, we prevent failure spread.

### Circuit breaker, the main idea

Stop sending traffic to an unhealthy dependency.

This sounds obvious, but most systems do the opposite. A service becomes slow, clients retry, more traffic reaches the unhealthy service, it becomes even slower, and recovery becomes harder. Circuit breakers exist specifically to stop this feedback loop.

> [!tip] Fail fast is healthier than fail slow
> Many engineers instinctively think "let us keep trying, maybe the service recovers". Production systems think "if a dependency is unhealthy, protect the rest of the platform first".

**Why fail fast matters.** Without a circuit breaker:

```text
Checkout Request
-> Payment Call
-> Wait 5 seconds
-> Timeout
-> Retry
-> Wait again
```

Every request occupies memory, sockets and worker capacity, and increases queue length. The dependency was already unhealthy, and now recovery is even harder.

With fail fast:

```text
Checkout Request
-> Payment Service unavailable
-> Immediate response
```

The request ends instantly, resources are released instantly, and the system remains stable.

**The states.** Normal operation is CLOSED and traffic flows normally. When failures exceed the threshold it becomes OPEN, traffic is blocked and requests fail immediately. After a cooldown it becomes HALF OPEN, a small amount of traffic is allowed and the dependency is tested. If healthy it goes back to CLOSED; if unhealthy back to OPEN.

Interviewers care more about the reasoning than the states themselves.

> [!warning] Circuit breakers can cause outages too
> Suppose the error threshold is 50 percent and a temporary network issue causes 55 percent failures. The breaker opens, but the actual dependency might have recovered already, so healthy traffic gets blocked. That is a false outage. Circuit breakers require tuning, monitoring and careful thresholds. They are not magic.

### Bulkheads

**The realisation.** Shared resources create hidden coupling.

Most outages happen because Service A fails and Service B dies too, even though Service B itself was healthy, because both were sharing resources.

**Example.** Checkout Service has 100 workers, and all of them can call Payment, Inventory and Notification. Notification hangs, so all 100 workers are waiting for notification. Payment cannot run, Inventory cannot run, Checkout appears dead, and yet Notification was the only unhealthy dependency. A classic production outage.

Instead of one giant shared pool, systems evolve toward separate Payment, Inventory and Notification capacity. Now Notification can fail while Payment, Inventory and Checkout survive. That is the essence of bulkheads.

**Shared resource collapse.** Shared thread pools, shared DB pools, shared Redis connections, shared Kafka consumers and shared worker processes all create hidden dependency coupling. The pattern is:

```text
Small local failure
-> Shared resource exhaustion
-> Global outage
```

**The Node.js perspective.** Node.js naturally shares a single event loop across everything, so one slow dependency can cause promise accumulation, socket accumulation, timer accumulation and memory retention. Eventually event loop lag starts affecting completely unrelated endpoints. One of the most common production surprises in Node.js systems.

### Graceful degradation

Strong systems do not think in terms of everything working or everything failing. They ask: what can I disable while keeping core functionality alive?

```text
Checkout        -> Works
Payment         -> Works
Recommendations -> Disabled
Analytics       -> Delayed
Notifications   -> Queued
```

One of the strongest signs of a mature architecture.

### Why both exist together

A very common senior question. Circuit breakers protect unhealthy dependencies from receiving more traffic. Bulkheads protect healthy parts of the system from unhealthy dependencies.

The circuit breaker protects the dependency. The bulkhead protects your own service.

---

## Stage 5: async processing and queue decoupling

**The core realisation.** Not every operation belongs in the critical path.

A critical path is the minimum set of work required before returning a response. Anything outside it becomes a candidate for Kafka, queues, asynchronous consumers and background processing.

**What is the critical path?** In an e-commerce checkout, some operations must complete before success can be returned: payment authorisation, inventory reservation, order creation. Without these the order is not actually complete, so they usually stay synchronous.

**What should leave it?** Email notifications, SMS notifications, analytics updates, recommendation refreshes, search indexing, audit processing. These are important but they do not determine whether checkout succeeded.

### Architecture evolution

Initially:

```text
Checkout
-> Payment
-> Inventory
-> Notification
-> Analytics
-> Search
```

Every dependency adds latency, failure risk, queueing risk and retry risk. Eventually:

```text
Checkout
-> Payment
-> Inventory
-> Kafka
```

then Kafka fans out to the Notification Consumer, Analytics Consumer, Search Consumer and Recommendation Consumer.

**The biggest benefit.** Before decoupling, checkout latency was payment plus inventory plus notification plus analytics plus search. After decoupling it is payment plus inventory plus the Kafka publish. That dramatically reduces response time, tail latency, dependency count and failure surface area.

### Kafka's real role

One of the biggest misconceptions is that Kafka is just a queue. In large architectures Kafka often acts as a temporal decoupling layer.

The producer says "I have recorded the event, my responsibility is complete". Consumers decide later when and how to process it. Producer and consumer lifecycles become independent.

**Temporal decoupling.** The producer and consumer do not need to be alive, healthy, or fast at the same time. Without it, the producer waits for the consumer. With it, the producer records the event and leaves.

> [!warning] Async does not remove work
> Many engineers subconsciously think async equals cheaper. It is not. Async does not remove work, it simply moves work. Before, the user waits. After, the queue waits. The work still exists, which is why consumer lag, queue depth, processing throughput and backlog growth become critical operational metrics.

### Eventual consistency

Checkout completes but the notification consumer has not processed the event yet, so temporarily the order exists and the notification is absent. The system disagrees with itself. A few seconds later the consumer catches up and the state converges.

You will keep seeing this concept in Kafka, Redis, CQRS, replication, projections and event driven systems.

**Async failures are harder to debug.** A synchronous failure means the request failed immediately, which is simple. An asynchronous failure means the request succeeded and the consumer failed 30 minutes later. Now engineers need tracing, replay, dead letter queues, lag monitoring and event correlation.

---

## Stage 6: fanout explosion and N+1 service calls

Until stage 5 we were mostly thinking about how one request travels through the system. Stage 6 changes the perspective entirely: how much work does one request create?

In production the bottleneck is often not the number of incoming requests, but the amount of work generated by each request.

> [!tip] The deepest lesson of this stage
> One request is rarely one unit of work.

A user refreshes their feed once. The infrastructure may perform hundreds of service calls, thousands of database lookups, cache reads, recommendation fetches, profile fetches and analytics fetches. The user sees 1 request; the infrastructure sees hundreds or thousands of operations.

### Request amplification

One incoming request generates many internal requests.

A user opens `GET /feed`. The Feed Service loads 100 posts, and for every post calls the Author Service, Comment Service and Reaction Service, giving 300 downstream calls for a single user request.

### N+1 is just a special case

Many engineers think the N+1 problem is only an ORM issue. Wrong. The ORM version is simply the most common example. The real problem is repeated dependent lookups, which can happen at database level, service level, cache level and API level. N+1 is one manifestation of request amplification.

**Service layer N+1.** The naive implementation looks correct and readable:

```js
async function getFeed(userId) {

  const posts =
    await postService.getPosts(userId);

  const result = [];

  for (const post of posts) {

    const author =
      await userService.getUser(
        post.authorId
      );

    const likes =
      await reactionService.getLikes(
        post.id
      );

    result.push({
      post,
      author,
      likes
    });
  }

  return result;
}
```

But 100 posts becomes 100 user requests plus 100 reaction requests. This is exactly how large systems accidentally melt themselves.

**The database version.** The same anti pattern:

```js
for (const order of orders) {

  await db.users.findOne({
    id: order.userId
  });

}
```

1000 orders becomes 1000 queries instead of `SELECT * FROM users WHERE id IN (...)`. The pattern is identical, only the layer changed. Patterns repeat across layers.

### Incoming traffic is not real traffic

Suppose 10,000 feed requests per second arrive. If each triggers 200 internal calls, the infrastructure sees 2,000,000 operations per second. That is the traffic that actually matters.

### Fanout and tail latency

Fanout means one operation triggers many downstream operations: social feeds, notification systems, recommendation engines, graph traversals, search systems. Fanout itself is not bad. Uncontrolled fanout is bad.

**Why fanout destroys p99.** One dependency that is 99 percent healthy sounds excellent. Now suppose 300 dependencies must complete. Probability says at least one will likely be slow, and the overall latency equals the slowest dependency latency. That is why fanout magnifies tail latency.

Users rarely complain about average latency. Users complain about worst latency, and fanout makes tail latency dominant.

### Fix 1: batching

```js
// Bad
await getUser(1);
await getUser(2);
await getUser(3);

// Good
await getUsers([1, 2, 3]);
```

Many requests become one request. This should immediately remind you of database write batching, Kafka batching and Redis aggregation. Same scaling pattern, different layer.

The deep principle: aggregate pressure before processing it.

### Fix 2: parallelisation

Sequential is additive:

```js
for (const post of posts) {
  const author = await getAuthor(post);
  const likes = await getLikes(post);
}
```

Better:

```js
await Promise.all([
  getAuthor(post),
  getLikes(post)
]);
```

Now the requests overlap, which reduces latency significantly.

> [!warning] `Promise.all` can become a production outage
> Many engineers stop at `Promise.all(...)` and think they solved scalability. `Promise.all(10,000 requests)` can create socket exhaustion, DB pool exhaustion, downstream overload and memory pressure. Everything from stage 3 returns.

### Fix 3: concurrency limiting

```js
const limit = pLimit(20);

await Promise.all(
  posts.map(post =>
    limit(() =>
      getAuthor(post.authorId)
    )
  )
);
```

Maximum 20 concurrent operations. This combines stage 3 backpressure with stage 6 fanout control.

### Precomputation

Eventually companies realise: why compute everything at request time? This introduces CQRS, projections, denormalisation and materialized views, which we already studied in read scaling. Instead of hundreds of live lookups, the system performs one projection lookup.

### Write time against read time fanout

One of the highest return interview discussions.

| Strategy | Advantages | Disadvantages |
| --- | --- | --- |
| Read time fanout, fetch everything when the user opens the feed | simpler writes, lower write cost | expensive reads, higher latency, request amplification |
| Write time fanout, update feed projections when the post is created | very fast reads, low request time fanout | more expensive writes, more storage, eventual consistency |

**The biggest takeaways.** One request is rarely one unit of work. Request amplification is often the real bottleneck. N+1 is a special case of request amplification. Fanout magnifies tail latency. Batching is one of the most powerful scalability techniques. Parallelisation helps, but unbounded parallelisation creates new bottlenecks. Concurrency control is as important as parallelism. Eventually mature systems move work from request time to write time using projections and precomputation.

> [!tip] The single most important sentence
> The bottleneck is usually not the incoming request itself. The bottleneck is the amount of work that request creates inside the system.

---

## Stage 7: Node.js event loop lag, thread starvation and GC pressure

Continuing the checkout example at 20,000 requests per second, the payment service latency suddenly increases from 100ms to 3 seconds. Notice the payment service did not crash. It simply became slow. That is how most production incidents begin: not with crashes, with slowness.

### Request retention

```js
async function checkout(req, res) {

  const payment =
    await paymentService.process();

  return res.json(payment);
}
```

This code looks harmless. Most developers think `await` is non blocking, which is true. But non blocking does not mean free.

While waiting for the dependency, Node.js still retains `req`, `res`, the promise state, closures, callback references and socket references. All of these remain alive until the request finishes. That is request retention.

### Memory leak against memory retention

Many engineers confuse these. They are not the same.

**A memory leak.** Objects are never released.

```js
const cache = [];

app.get('/user', async (req, res) => {

  const user = await getUser();

  cache.push(user);

  res.send(user);
});
```

Memory grows forever and objects remain reachable forever.

**Memory retention.** Objects should eventually disappear but remain alive much longer than expected. `await slowDependency()` means the request is waiting, Node cannot free request related objects yet, and memory usage rises. Eventually memory will be reclaimed.

A huge number of production incidents are caused by retention rather than actual leaks.

### Promise accumulation

```js
const results = await Promise.all(
  massiveArray.map(processItem)
);
```

Looks elegant, looks scalable, can be disastrous. With 100,000 promises, Node must maintain state, callbacks, closures and references for all of them, so memory pressure grows rapidly.

If `users = 100,000`, `Promise.all(users.map(fetchProfile))` may start 100,000 concurrent operations, causing socket exhaustion, Redis overload, DB pool exhaustion, memory pressure and downstream collapse. This connects directly back to stage 3 backpressure and stage 6 fanout explosion.

### Event loop lag

The difference between when a task should execute and when it actually executes.

```js
setTimeout(() => {
  console.log('hello');
}, 100);
```

Expected 100ms, actual 3000ms, because the event loop was busy. That delay is event loop lag.

**Why it matters.** Many engineers only watch CPU and memory. A Node.js service may show CPU at 40 percent and memory at 60 percent and still be unhealthy, because event loop lag is 3 seconds. Callbacks, responses, timers and promises are all delayed, and users experience terrible latency.

**The common senior question.** "CPU is 40 percent, memory is fine, but latency is terrible. What is your hypothesis?" A strong answer is event loop lag, then investigate synchronous CPU work, GC pauses, promise accumulation and thread pool saturation.

### CPU bound work

Node.js performs poorly when CPU heavy work stays on the request path.

```js
app.get('/report', (req, res) => {

  const result =
    generateHugeReport();

  res.send(result);
});
```

If `generateHugeReport()` takes 5 seconds, the event loop is blocked for those 5 seconds, other requests wait, and the entire service appears frozen.

CPU heavy work should move to worker threads, background workers, separate services, or queue based processing. Never keep expensive CPU work on the request path.

### Garbage collection pressure

As memory grows, GC cycles become larger, larger GC cycles cause longer pauses, and longer pauses increase event loop lag. Another feedback loop.

### The Node.js death spiral

```text
Slow Dependency
-> Request Retention
-> Memory Growth
-> GC Pressure
-> Event Loop Lag
-> Higher Latency
-> More Request Retention
-> More Memory Growth
```

Nothing crashes. No obvious error appears. Yet the service becomes unusable. A classic Node.js production failure pattern.

### Thread starvation

Many Node.js engineers think Node.js equals a single thread. Partially true. Node also uses the libuv thread pool for crypto, file system operations, DNS and compression, with a default size of 4 threads.

Suppose the application uses `bcrypt.hash(...)` heavily. Traffic spikes, thousands of password operations arrive, the libuv thread pool fills, new crypto operations wait, and latency rises. That is thread starvation.

> [!warning] Thread pool saturation looks like a DB issue
> Symptoms are API latency rising, so engineers immediately inspect PostgreSQL, Redis and Kafka. The actual problem may be libuv thread pool saturation. A classic senior level debugging insight.

### Metrics you should watch

For Node.js services, do not stop at CPU and memory. Also monitor event loop lag, GC duration, heap usage, open handles, pending promises, active requests, socket count and thread pool utilisation. These often reveal problems much earlier.

### Common questions from this stage

What is event loop lag? Why can a Node.js service be slow when CPU is low? What is the difference between a memory leak and memory retention? Why can `Promise.all` become dangerous? What metrics would you inspect during latency spikes? What causes GC pressure? What is the Node.js death spiral? What is thread starvation? What is libuv thread pool saturation? When should worker threads be used?

> [!tip] The single most important sentence
> A Node.js service usually dies from accumulated pressure long before it dies from a crash.

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
| Memory | allocate, retain objects, heap growth, GC pressure, OOM |
| Database connections | acquire, forget release, pool exhaustion, request blocking |
| Kafka | produce messages, consumer falls behind, lag grows, queue collapse |
| Sockets | open socket, forget cleanup, file descriptor exhaustion, network failures |

### Queue collapse

The most important system design equation:

```text
Arrival Rate > Processing Rate
```

When this holds, queue growth is eventually infinite.

**Example.** Incoming 20,000 messages per second, consumer 15,000 per second, difference 5,000 per second. The queue grows forever. After one minute that is 300,000 extra messages; after ten minutes, 3 million.

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

No TTL, no eviction, no size limit. Looks harmless. Eventually the cache grows infinitely, which is effectively a memory leak with a nicer name.

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

**Connection pool exhaustion.** Pool size 100, leaking one connection per request, eventually 100 leaked connections. New requests cannot obtain connections, latency rises, timeouts appear, and the system looks slow. The root cause is a resource leak.

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

## How the stages connect

| Stage | Teaches |
| --- | --- |
| 1 | latency propagates |
| 2 | retries amplify pressure |
| 3 | systems must reject work under overload |
| 4 | failures must be isolated before they spread |
| 5 | remove unnecessary work from the critical path |
| 6 | reduce the amount of work each request creates |
| 7 | understand what happens inside the process after pressure arrives |
| 8 | pressure remains in the system when resources are not released |

Notice how naturally the evolution progresses, from handling requests toward surviving failures. That transition is the entire purpose of the service layer.

# Event Loop Lag and Pressure

> [!tldr]
> Node.js services die from accumulated pressure inside the process through promise retention, memory growth, GC pauses and event loop starvation, not from crashes.

Part of [[service-layer]].

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

This looks clean and scalable, but it can be disastrous. With 100,000 promises, Node must maintain state, callbacks, closures and references for all of them, so memory pressure grows rapidly.

If `users = 100,000`, `Promise.all(users.map(fetchProfile))` may start 100,000 concurrent operations, causing socket exhaustion, Redis overload, DB pool exhaustion, memory pressure and downstream collapse. This connects directly back to stage 3 backpressure and stage 6 fanout explosion.

### Event loop lag

Event loop lag is the difference between when a task should execute and when it actually executes.

```js
setTimeout(() => {
  console.log('hello');
}, 100);
```

The timer was expected to fire after 100ms; it actually fired after 3000ms, because the event loop was busy. That delay is event loop lag.

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

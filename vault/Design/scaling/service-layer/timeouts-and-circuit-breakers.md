# Timeouts and Circuit Breakers

> [!tldr]
> Overloaded systems must intentionally reject work and isolate failures before they spread, through timeouts, backpressure, circuit breakers and bulkheads.

Part of [[service-layer]].

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

# Latency and Retries

> [!tldr]
> Microservices amplify latency through synchronous chains and retries, creating cascading failures through repeated traffic multiplication.

Part of [[service-layer]].

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

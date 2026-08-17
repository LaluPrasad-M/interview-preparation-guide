# Fault Tolerance

> [!tldr]
> Isolating failures so one dead dependency does not take the rest of the system with it. Ten techniques, and the one sentence answer that covers them.

---

## The one sentence answer

> [!tip] Say this
> Fault tolerance in microservices means isolating failures so that if one service or dependency goes down, the rest of the system continues working. We achieve it using circuit breakers, retries, timeouts, bulkheads, caching, redundancy, load shedding and graceful degradation.

---

## 1. Circuit breaker, the most important

Protects a service from repeatedly calling a failing service.

**The scenario.** Service A depends on service B, and B goes down.

**Without a breaker.** A keeps calling B, threads pile up, A becomes slow, and A eventually crashes. That is a cascading failure.

**With a breaker.** After a few failures the circuit opens, A stops calling B and returns a fallback response instead, and the system survives.

Tools: Hystrix, Resilience4J, Envoy, Istio.

---

## 2. Timeouts

Never wait forever. If a service takes longer than your budget, for example 200 ms, time out and return a fallback rather than blocking the thread pool.

---

## 3. Retries with backoff, not blind retries

Retry only when the response is a 5xx, when it is a network glitch, and when the operation is idempotent.

Use exponential backoff, jitter and a maximum retry count. See [[exponential-backoff]] and [[idempotency]].

---

## 4. Bulkheads

Separate resource pools so one failing service cannot exhaust the others.

If the payment API is slow, the product page should not freeze. Put them in separate thread pools, which isolates the failure.

---

## 5. Graceful degradation and fallbacks

If a service fails, degrade rather than break. Show the product without recommendations. Show cached data. Show the last known price. Show a temporarily unavailable message rather than crashing the whole page.

---

## 6. Load shedding, rejecting early

If a service is overloaded, immediately reject low priority traffic. Better to reject 10 percent than to crash entirely.

---

## 7. Rate limiting and throttling

Protects your services from traffic spikes, denial of service, and internal misuse.

---

## 8. Caching

If a downstream service fails, serve cached data. This is one of the best fault tolerance patterns, and the reason a cache is not only a latency tool. See [[caching-problems]].

---

## 9. Redundancy and replicas

Run multiple replicas of each service. If one crashes the load balancer routes traffic to the others, which lowers downtime.

---

## 10. Event driven async communication

Instead of synchronous calls, which are prone to cascading failures, use Kafka, a managed queue or pub/sub. If a consumer is slow, messages wait in the queue and the system does not break.

---

## Related

The stage by stage version of these failures, with code, is in [[service-layer]].

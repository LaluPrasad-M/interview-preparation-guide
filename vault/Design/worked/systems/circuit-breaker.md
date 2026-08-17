# Circuit Breaker, as a Design Question

> [!tldr]
> Say "this is a state machine problem" early. The interesting parts are where the state lives and the four ways it fails in production.

The technique in one paragraph is in [[fault-tolerance]]. This note is the full design answer.

---

## The prompt

You are building a service that depends on a third party payment API. It is sometimes slow, sometimes failing, occasionally down. Design a circuit breaker to prevent cascading failures, protect your service from overload, and allow recovery.

**Constraints to assume, or ask for.** Traffic of 5k to 20k RPS. The external API has a p99 of 2 to 5 seconds during failures, with timeouts, 5xx errors and partial outages. Your service must respond within 200 ms and must not go down because of this dependency. You may use in memory state, Redis, and background jobs, in a multi instance stateless environment behind a load balancer.

---

## What a breaker actually does

**Fail fast.** If a downstream service is slow or failing, stop waiting for timeouts every time.

**Protect your system.** Avoid thread pool exhaustion, connection pool exhaustion, latency cascading upstream, and retry storms that make it worse.

**Improve availability.** With fallback logic you return cached or default data instead of going down with the dependency.

---

## Functional requirements

Detect when the external API is unhealthy. Stop sending requests once failures cross a threshold. Allow limited retry attempts to check recovery. Fail fast while open. Resume normal traffic once it recovers.

---

## Non functional requirements, with justification

| Dimension | Requirement, and why |
| --- | --- |
| Low latency, fail fast | if a dependency is slow or failing, the breaker has to short circuit the call immediately so upstream threads are not blocked and the latency does not cascade |
| High availability | the breaker sits inline with the request path, so if it becomes a point of failure it undermines the whole resilience strategy |
| Fault isolation | when a downstream dependency turns unhealthy, the breaker isolates that fault so the rest of the system keeps responding, even in a degraded state |
| Correctness over freshness | during partial failure, users prefer correct but slightly stale data over a timeout or a 500, which keeps the experience functional while the system heals |
| Minimal overhead per request | the breaker wraps every outbound request on the hot path, so it must add almost no CPU or memory overhead or it becomes the bottleneck |

---

## The state machine

| State | Meaning | Behaviour |
| --- | --- | --- |
| Closed | the dependency is healthy | send requests normally |
| Open | the dependency is unhealthy | block requests immediately, fail fast |
| Half open | testing recovery | allow a small number of trial calls |

**Closed.** All requests are allowed. Track failure count, timeout count and a rolling error rate over, say, the last 30 seconds. Transition to open when the error rate exceeds a threshold, or consecutive failures exceed N.

**Open.** Do not call the external API. Immediately return a cached response, a fallback, or a graceful error. Stay open for a cool down period, for example 30 seconds.

**Half open.** Allow limited test traffic, for example 1 to 5 requests. Good success rate closes the breaker, failure reopens it.

> [!warning] Open never goes straight to closed
> After the cool down window expires the breaker moves to half open, not closed. Skipping that step sends full traffic at a dependency you have not verified.

---

## The request flow

An incoming request hits your service, the breaker intercepts before the external call, a decision is made based on state, and it either calls the API or fails fast with a fallback. Metrics update asynchronously.

```js
if (circuit.isOpen()) {
  return fallbackResponse()
}

try {
  const res = callExternalAPI()
  circuit.recordSuccess()
  return res
} catch (err) {
  circuit.recordFailure()
  if (circuit.shouldOpen()) {
    circuit.open()
  }
  return fallbackResponse()
}
```

You do not need more code than this in an interview.

---

## Where does the state live

The interviewer will ask this.

**In memory, per instance.** Very fast, but inconsistent across instances.

**Redis, shared.** Consistent behaviour, but adds latency.

> [!tip] The answer that lands
> Keep counters locally for speed and periodically sync breaker state to Redis, which avoids thundering herd problems without putting Redis on the hot path.

---

## What goes wrong in production

> [!warning] Thundering herd
> All instances switch to half open at once and flood the recovering API. Fix with randomised probe requests or leader based probing.

> [!warning] Flapping
> The breaker oscillates between open and closed because thresholds are badly tuned. Fix with rolling window metrics and a minimum open duration.

> [!warning] The circuit never closes
> Success criteria are too strict. Fix with a gradual traffic ramp up.

> [!warning] Shared Redis failure
> The breaker logic becomes a new single point of failure. Fix with a graceful fallback to local state.

---

## Observability

**Metrics.** Circuit state transitions, failure rate, external latency.

**Alerts.** Circuit open too long, dependency SLA breach.

**Dashboards.** Error budgets, dependency health.

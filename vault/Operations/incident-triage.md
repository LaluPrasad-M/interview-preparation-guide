# Incident Triage

> [!tldr]
> Production breaks in a small number of recognisable shapes. The job during an incident is matching the shape fast, not reading every dashboard in order.

---

## The golden signals

| Signal | Question it answers |
| --- | --- |
| Latency | how long are requests taking |
| Traffic | how many requests are arriving |
| Errors | what fraction are failing |
| Saturation | how full are CPU, memory, connections, queues |

Almost every incident is one of these four moving first, with the others following as a consequence.

---

## Signal to hypothesis to verification

Do not jump straight to a fix. Move in three steps:

1. **Signal.** What actually changed? [[p99-latency|P99 latency]] jumped, error rate climbed, a queue is growing.
2. **Hypothesis.** What would produce that specific signal? A slow downstream dependency produces latency without errors. A bad deploy produces errors without latency. GC pressure produces latency with high CPU.
3. **Verification.** Check the one metric that would confirm or kill the hypothesis before acting on it. Do not restart a service to "see if it helps", that destroys the evidence.

---

## The five numbers to pull first

Ask one question before any of them: did anything ship?
A deploy, a config change or a feature flag flip just before the alert is the most likely cause and the fastest thing to undo.

Then, before touching a dashboard, get these five in order:

1. **Error rate.** Is anything actually failing, or just slow?
2. **P50 versus P99 latency.** Is everything a little slower, or is a subset badly slow?
3. **Traffic volume.** Did request volume change, or is the same volume behaving differently?
4. **CPU.** Is a process pegged?
5. **Event loop lag** (for Node services). Is the process busy, or just blocked waiting on something else?

Those five numbers usually narrow the incident to one of the patterns below before you open a single log.

The order after that is always the same: metrics say what is wrong, traces say where the time went, logs say why it happened.
Read them in that order and you stop searching logs for something you cannot describe yet.

---

## CPU and latency, the two-pattern read

| Pattern | CPU | Event loop lag | Usual cause |
| --- | --- | --- | --- |
| Compute bound | high | high | CPU-heavy code running synchronously on the main thread |
| I/O bound | low or normal | low | a downstream dependency is slow, the process itself is idle and waiting |
| Starved | low | high | something is blocking briefly and often, GC pauses, a synchronous call, or an unbounded queue backing up |
| Busy off the main thread | high | low | the work is real but it is not on your thread, usually the libuv thread pool full of `crypto` or `fs` jobs, see [[event-loop-lag]] |

The trap is treating them all the same way. Scaling out more instances helps the compute-bound case, does nothing for the I/O-bound case, and can make the starved case worse by adding more idle-but-blocked processes.

Event loop lag is the metric that splits them, which is why it goes in the first five numbers you pull.
Most people jump to CPU, and CPU alone cannot tell a busy process from a blocked one.

Once you know the shape, [[where-to-look-by-component]] has the signal to cause to next step table for whichever component you landed on.

---

## When P99 jumps but the average does not

A flat average with a climbing P99 means most requests are fine and a minority are very slow, not that everything got a little slower. Averaging hides this, which is why P99 (or P95) is the number worth alerting on, not the mean.

**Segment before you dig.** Break the slow requests down by:

- endpoint, is it one route or all of them
- customer or tenant, is it one account hitting an unusual code path
- time of day, does it line up with a batch job, a cron, or a traffic peak
- deploy time, did it start right after a release

A P99 spike isolated to one endpoint or one tenant is a different investigation than one affecting every request at once.

---

## Alerts versus dashboards

Alerts should fire on P95 or P99 and on error rate, the numbers that catch a minority of users having a bad time. Dashboards can show averages for a general sense of health, but an average-based alert stays quiet exactly while a real incident is underway for 1 percent of traffic.

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[node-profiling]] | `JavaScript/node/` | the tools for reading CPU, GC and event loop lag directly, not the triage process |
| [[event-loop-lag]] | `Design/scaling/service-layer/` | the mechanics of why Node's single thread produces this pattern |
| [[lag-and-dead-letter-queues]] | `Kafka/` | the equivalent triage framework for Kafka consumer lag specifically |

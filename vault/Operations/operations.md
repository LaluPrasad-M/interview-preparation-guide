# Operations

> [!tldr]
> Index for everything under `Operations/`. What breaks in production, how to triage an incident once it starts, and where metrics and logs actually live.

---

## Notes

| Note | Covers |
| --- | --- |
| [[what-breaks-in-production]] | the ten buckets most production incidents fall into |
| [[incident-triage]] | golden signals, the two-pattern CPU/latency read, and segmenting a P99 spike |
| [[prometheus-grafana-loki]] | the pull model, where logs live, and correlating a spike across both |
| [[where-to-look-by-component]] | one table per component: the signal, the likely cause, and the next place to look |

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[lag-and-dead-letter-queues]] | `Kafka/` | the Kafka lag investigation framework, not a general incident note |
| [[service-layer]] | `Design/scaling/` | latency amplification and retry storms as a design concept, not an incident |
| [[kubernetes-basics]] | `Cloud/kubernetes/` | debugging a stuck pod is a Kubernetes note, not an incident category |
| [[circuit-breaker]] | `Design/worked/systems/` | the state machine and where its state lives, not incident response |
| [[node-profiling]] | `JavaScript/node/` | the Node-specific profiling tools, CPU, GC and event loop, not the triage process itself |

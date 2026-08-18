# Backend

> [!tldr]
> Transport and protocol decisions that do not belong to any one framework.

---

## API design

| Note | Covers |
| --- | --- |
| [[api-design]] | the design flow, pagination, filtering, sorting, auth, why injection happens, status codes, observability, versioning, in four parts: fundamentals, advanced, security and observability |
| [[idempotency]] | the techniques, partial failures, async consumers, and the seven point failure checklist |
| [[api-failure-scenarios]] | seven APIs, seven failures, and the 22 row correctness toolbox, in three parts: distributed failures, financial failures |
| [[http-status-codes]] | the master table plus the pairs that get asked |

---

## Realtime

| Note | Covers |
| --- | --- |
| [[websockets-and-sse]] | the feature comparison, the golden rule for choosing, and a transport table for a voice pipeline |

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[jwt]] | `Security/` | auth tokens are a security topic, not an API design one |
| [[webhook-signatures]] | `Security/` | verifying a webhook is a signature scheme, not a transport decision |
| [[websocket-bridge]] | `Kafka/` | the fan out design lives with the Kafka mechanics it depends on |
| [[ai-tool-idempotency]] | `Design/worked/systems/` | a worked design applying idempotency, not the concept itself |
| [[webhook-delivery]] | `Design/worked/systems/` | it is a full worked design, not the transport decision this folder holds |
| [[webhook-ingestion]] | `Design/worked/systems/` | same reason: a worked design, not a protocol note |

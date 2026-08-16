# Backend

> [!tldr]
> Transport and protocol decisions that do not belong to any one framework.

---

## API design

| Note | Covers |
| --- | --- |
| [[api-design]] | the design flow, pagination, filtering, sorting, auth, why injection happens, status codes, observability, versioning |
| [[idempotency]] | the techniques, partial failures, async consumers, and the seven point failure checklist |
| [[api-failure-scenarios]] | seven APIs, seven failures, and the 22 row correctness toolbox |
| [[http-status-codes]] | the master table plus the pairs that get asked |

---

## Realtime

| Note | Covers |
| --- | --- |
| [[websockets-and-sse]] | the feature comparison, the golden rule for choosing, and a transport table for a voice pipeline |

---

## Related, filed elsewhere

Auth tokens are in [[jwt]]. Webhook security is in [[webhook-signatures]]. The Kafka to Redis to WebSocket fan out is in [[websocket-bridge]].

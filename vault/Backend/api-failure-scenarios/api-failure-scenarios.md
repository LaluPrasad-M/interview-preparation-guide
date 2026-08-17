# Seven API Failure Scenarios

> [!tldr]
> Seven APIs, seven different ways they break, seven different fixes. If you can name the failure and the principle for each, you can design almost any write path.

---

## The summary first

| API | Core failure | Core principle |
| --- | --- | --- |
| Wallet transfer | lost update | row level locking |
| Payment | external success before the DB save | state machine plus reconciliation |
| Order plus inventory | distributed transaction | saga compensation |
| File upload | partial external success | compensating cleanup |
| Subscription renewal | job duplication | unique constraint idempotency |
| Ride assignment | double assignment | atomic conditional update |
| Crypto withdrawal | async plus webhook retry | outbox plus idempotency |

---

## The parts

| Note | Covers |
| --- | --- |
| [[api-failures-financial]] | wallet transfers and external payment processing |
| [[api-failures-distributed]] | multi-service failures, async work, and the correctness toolbox |

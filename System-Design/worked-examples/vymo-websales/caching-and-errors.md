# Caching and Error Handling

> [!tldr]
> Three caches with three different TTLs, each matched to how often the underlying data changes, and one failure response per failure type.

---

## What is cached

From the high level design:

| Data type | Store | TTL | Purpose |
| --- | --- | --- | --- |
| Leads data | Redis | 30 minutes | hot cache for faster access |
| Officer hierarchy | Redis | 24 hours | RBAC role caching |
| Metric search | Elasticsearch | no TTL | search query results |

From the low level design, with what invalidates each one:

| What gets cached | Store | TTL | Invalidated by |
| --- | --- | --- | --- |
| Officer hierarchy | Redis | 24 hours | the weekly file upload |
| Lead assignments | Redis | 30 minutes | agent reassignment |
| Lead notifications | Redis | 5 minutes | read acknowledgement |

> [!tip] The TTL follows the change rate, not the traffic
> The officer hierarchy arrives once a week, so a 24 hour TTL risks at most a day of staleness on data that changes weekly. Lead assignments change whenever a lead is reassigned, so 30 minutes. Notifications are read within minutes, so 5.
>
> That is the reasoning to reproduce in an interview: pick the TTL from how quickly the truth moves, then check the invalidation path covers the cases where it moves sooner.

Note that the hierarchy has both a TTL and an explicit invalidation on upload. The TTL is the safety net for a missed invalidation, not the primary mechanism.

---

## Error handling

| Error type | Action |
| --- | --- |
| Corrupted file | alert plus re-trigger |
| SFTP connectivity | retry plus alert |
| API failure | retry plus dead letter queue |

Three different shapes of failure, three different answers.

**A corrupt file will not fix itself**, so retrying is pointless and a human has to look. Hence alert first.

**SFTP connectivity is usually transient**, so retry, and alert only because a silent retry loop hides an outage.

**A failed API call goes to a dead letter queue**, which is the important one: the message is not lost and not retried forever. It waits somewhere you can inspect and replay it.

> [!warning] A dead letter queue nobody reads is a bin
> The queue only helps if something alerts on its depth. Otherwise failures accumulate quietly and you find out weeks later that a class of lead was never processed.

Retries here should use [[exponential-backoff]], and the SLA tracking in [[lld]] is what tells you whether the retries are still inside the 30 second budget.

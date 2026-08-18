# Low Level Design

> [!tldr]
> The same system one level down: which service speaks which protocol, and the ordered steps inside each flow.

---

## Service contracts, with data flow type

| Service | Protocol | Purpose | Flow |
| --- | --- | --- | --- |
| LMS | HTTP | lead management | sync and async |
| DDP | SFTP and Kafka | file processing | async |
| CRM | Kafka | call centre integration | async |
| Notification service | Kafka | push notifications | async |
| Calendar service | Kafka | auto meeting scheduling | async |
| Metric service | HTTP | search and lead reporting | sync |

LMS is the only entry that is both, because it answers the website synchronously and then publishes events.

---

## SFTP file processing, inside DDP

1. Download the file.
2. Decrypt it.
3. Validate it, both schema and content.
4. Parse it, CSV or JSON.
5. Publish Kafka events.
6. Retry on failure, with the re-trigger path.
7. Alert on errors, to Sentry and Slack.

The order matters. Validation sits before publishing, so a corrupt file produces one alert rather than thousands of bad events that then have to be undone.

---

## Lead creation flow

```text
POST /v1/leads
```

1. Validate the input, phone number and policy details.
2. Check for duplicates.
3. Encrypt the sensitive fields.
4. Produce a Kafka event.
5. Save to the database, MongoDB.
6. Trigger a notification for high priority leads.

> [!warning] Two ordering questions in this list
> Publishing the event before saving means a consumer can be told about a lead that is not in the database yet, and a failed save leaves an event that refers to nothing. The safer arrangement is save first, then publish, or write the event into the same transaction as the record, which is the outbox pattern.
>
> Duplicate checking before encryption also means the duplicate check is comparing plaintext, which is what you want, since deterministic encryption would be needed to compare ciphertext. Worth stating out loud rather than leaving implied.

---

## Lead assignment, RBAC based

1. Map the hierarchy: Relationship Banker, Branch Manager, ZTM.
2. Look up the cache in Redis.
3. Apply reassignment rules when an agent is inactive.
4. Trigger the notification service.
5. Apply the escalation policy.

---

## Call centre integration

1. Send outbound requests from LMS to CRM.
2. Provide callback APIs.
3. Acknowledge the response.
4. Retry on errors.
5. Track the [[sli-slo-and-sla|SLA]].

---

## Zoom meeting auto scheduling

1. Consume the Kafka event.
2. Call the calendar service.
3. Call the Zoom API.
4. Trigger a notification.
5. Persist the meeting link.

Persisting the meeting link is the step that matters for recovery. If the notification fails, the link still exists and can be resent, rather than the meeting being lost because its only copy was in a push message.

---

## Metric service integration

1. Query Elasticsearch.
2. Insert in bulk.
3. Paginate results.
4. Optimise the index.

Bulk insert rather than one document per call is the difference between Elasticsearch keeping up and falling behind, since each request carries indexing overhead that batching [[amortised-analysis|amortises]].

Caching and failure handling are in [[caching-and-errors]].

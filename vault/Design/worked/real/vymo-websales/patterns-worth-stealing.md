# Patterns Worth Stealing

> [!tldr]
> The reusable half of this example, with no client, no company and no real numbers. This is the version to talk about in an interview, and the version to reach for when designing something similar.

---

## Split the path by whether anyone is waiting

One synchronous entry point, everything after it asynchronous.

The caller waits for the things it must know about, which are validation, storage and routing. It does not wait for notifications, scheduling or downstream reporting, because nothing upstream depends on those succeeding.

That split is what makes a tight end to end target achievable. Widening it is the usual mistake: as soon as the caller waits for the notification, your latency is the notification provider's latency.

---

## Live path and batch path over one data model

A record can arrive two ways, an API call now or a file on a schedule, and both produce the same record.

Two things make this work. The batch path upserts rather than inserts, so a lead that came in live and again in the file does not duplicate. And the batch path validates the whole file before publishing anything, so a corrupt file produces one alert instead of thousands of bad events you then have to undo.

---

## Check the cache, take the lock, check again

The pattern from [[locks]], applied here as: read cache, on a miss do the expensive work, write the cache.

Under concurrency you want the second check after acquiring the lock, or every waiter repeats the work the first one just finished.

---

## Set the TTL from the change rate

Not from traffic, and not from a default.

| Data changes | TTL |
| --- | --- |
| weekly, by an upload | a day, with explicit invalidation on upload |
| whenever someone reassigns it | tens of minutes |
| read within minutes | a few minutes |

Where an explicit invalidation exists, the TTL is the safety net for a missed invalidation rather than the primary mechanism. Say that out loud, because "why both" is the follow up question.

---

## One failure response per failure shape

| Failure | Response | Why |
| --- | --- | --- |
| Bad input that cannot succeed on retry, like a corrupt file | alert a human | retrying a corrupt file just corrupts faster |
| Transient connectivity | retry with backoff, and alert so the retries are visible | it will probably work in a minute |
| A downstream call that failed | dead letter queue | not lost, not retried forever, inspectable and replayable |

Then alert on the depth of that dead letter queue, or it is a bin rather than a queue.

---

## Persist the artefact, not just the message

When a flow produces something a user needs, a meeting link, a document, a reference number, store it before you notify anyone.

Then a failed notification is a resend rather than a loss. The version of this that bites is a system whose only copy of the link was inside the push notification that failed to deliver.

---

## Publish after you commit, or use an outbox

If you publish an event before the write commits, a consumer can be told about a record that does not exist yet, and a failed write leaves an event pointing at nothing.

Either save first and then publish, or write the event into the same transaction as the record and let a separate process ship it. That second option is the outbox pattern, and it is the answer when you need the event and the record to be all or nothing.

---

## Where these came from

Extracted from [[vymo-websales]]. The concepts they lean on are in [[designing-the-four-layers]], [[message-ordering]] and [[locks]].

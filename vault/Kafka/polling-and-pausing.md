# Polling and the Pause Resume Pattern

> [!tldr]
> `consumer.pause()` stops fetching but keeps heartbeating. That is how you build a delayed retry pipeline without getting kicked out of the consumer group.

---

## Why you cannot just sleep

If you put a `setTimeout(60000)` in a Kafka consumer, the consumer dies.

Kafka expects the consumer to process messages quickly. If you sleep for 60 seconds, Kafka assumes your server crashed, kicks it out of the consumer group, and triggers a massive rebalance, which brings the whole system to a halt.

---

## The natural ordering of failures

The consumer does not have to guess timestamps, because Kafka is a strictly ordered log.

If message A fails on the main topic at `10:00:00`, it is pushed to `retry_1m`. If message B fails at `10:00:15`, it is pushed to `retry_1m` behind message A.

Because time moves forward, the messages in the `retry_1m` topic are already perfectly sorted by their failure time.

---

## What `consumer.pause()` actually does

Pause does not mean freezing the process like a `sleep()`. It means telling the Kafka client library, for example KafkaJS, to change its network behaviour.

A Kafka consumer does two things under the hood:

1. **Fetching.** It pulls new data from the broker.
2. **Heartbeating.** It pings the broker every 3 seconds, saying "I am still alive, do not kick me out."

Calling `consumer.pause()` says: stop fetching new messages, but keep sending heartbeats.

---

## The step by step flow for the 1 minute wait

Here is exactly what happens in the `retry_1m` worker.

1. **The fetch.** The worker pulls message A from the `retry_1m` topic.
2. **The math.** It reads message A's payload: `failed_at: 10:00:00`. The current clock says `10:00:10`.
3. **The pause.** It needs to wait 50 more seconds, so it calls `consumer.pause()`.
4. **The wait.** It uses a standard `setTimeout` for 50 seconds. During those 50 seconds the Kafka library keeps sending heartbeats in the background.
5. **The execution.** The timer fires and the worker executes the database logic for message A.
6. **The resume.** It calls `consumer.resume()`.
7. **The next fetch.** It immediately fetches message B, which failed at `10:00:15`. The current time is now `10:01:00`, so it waits 15 seconds, executes, and resumes.

---

## Does this block the whole partition?

Yes, and that is exactly what we want.

If message A is not ready to be processed yet, it is physically impossible for message B to be ready, because message B failed after message A. By pausing the entire `retry_1m` partition, we enforce a strict one minute delay pipeline.

Meanwhile the main topic is completely unaffected and keeps processing fresh webhooks at 10,000 [[qps|QPS]].

# Interview Experiences

> [!tldr]
> What was actually asked in each round, and where it went wrong. Interview company names stay in this area.

---

## Before any interview

Brush up the project story and resume projects in detail.

---

## BigStep

**Topics probed.** Memory leaks. The event loop. N plus 1 queries and how to manage them. Child process against worker thread.

### The output order puzzle

```js
console.log("1111")
setTimeout(() => { console.log("2222") }, 0)
const promise = new Promise((resolve, reject) => {
  console.log("3333");
  resolve("4444");
})
promise.then((result) => { console.log(result) })
console.log("5555")
```

The actual output, verified by running it:

```text
1111
3333
5555
4444
2222
```

The promise executor body runs synchronously, so `3333` prints before `5555`. Only the `.then` callback is deferred, onto the microtask queue, which is why `4444` lands after all the synchronous logging but before the `setTimeout`.

> [!warning] The transcript recorded this wrong
> The chat log from the round has `5555` before `3333`, which would mean the executor body ran late. It does not. If you were the one who answered, this is the exact thing to get right next time. See [[engine-internals]] for the priority rule.

### The coding question

Given an array of positive integers and a target sum, find the minimal length of a contiguous subarray whose sum is at least the target. Return 0 if none exists.

With `target = 7` and `nums = [2,3,1,2,4,3]`, the expected result is 2, from the subarray `[4,3]`.

The reasoning written out live: maximise the sum while minimising the array size, and because there are multiple answers, track the minimum. Prefix sum leads to it, but sliding window is the direct route.

```js
let nums = [2, 3, 1, 2, 4, 3]
let target = 7
let r = 0, min = Infinity, sum = 0
for (let l = 0; l < nums.length; l++) {
  sum += nums[l]
  while (sum >= target) {
    min = Math.min(min, l - r + 1)
    sum = sum - nums[r]
    r++
  }
}
console.log(min)
```

> [!warning] What this code as written misses
> The spec says return 0 when no subarray qualifies, but `min` is still `Infinity` in that case. `f([1,1,1], 100)` prints `Infinity`, not `0`. The last line needs to be `console.log(min === Infinity ? 0 : min)`. The window logic itself is correct, so this is the cheap point to lose and the easy one to remember.

See [[sliding-window]] for the general template.

---

## DexCare

Roman to integer and the reverse. Design a search system.

See [[typeahead-search]].

---

## Invenco, round 2

Why microservices? Managing data inconsistency. Database choices and the reasoning behind them. AI and its usage. How do you manage version sync in deployment across services? Resume follow up on encryption and decryption details.

---

## ZoomInfo, round 1

I missed the webhooks part, and got confused about where to put Kafka.

### The prompt

Design an endpoint that receives webhook events from a CRM whenever a contact is created or updated. Assume moderate volume, a few hundred events per hour.

**Constraints.** The CRM retries webhook delivery if you do not respond within 5 seconds. Events may arrive out of order or duplicated.

### What I put on the board

**Functional requirements.** The API. Idempotency. Events unordered. Multi tenancy.

**Non functional.** Write heavy. Latency matters. Highly available.

```text
+-------------+        +--------------+         +---------+
| API Gateway | --id-> | Webhook svc  | <-----> |  Redis  |
+-------------+        +--------------+         +---------+
                              |
                              v
                       +--------------+
                       |  (processor) |
                       +--------------+
                              |
                              v
                       +--------------+
                       |   MongoDB    |
                       +--------------+
```

**The API.**

```text
POST /v1/contact/{id}
{
  "id": ""
}
```

### What was missing

The board never answered the two constraints it listed. There is no dedupe key reaching Redis, no timestamp comparison on the Mongo write, and no queue between the receiver and the processor, which is what the 5 second retry budget demands.

[[webhook-ingestion]] has the shape this should have been: return `202` fast, partition by contact ID, and let an `INSERT ... ON CONFLICT` with a timestamp guard resolve both duplicates and out of order arrival. [[webhook-delivery]] is the sender side of the same problem, and [[internals]] covers when Kafka belongs in a design at all.

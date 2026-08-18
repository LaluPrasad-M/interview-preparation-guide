# Rate Limiter, In Process

> [!tldr]
> Two small classes that come up in machine coding rounds: a token bucket driven by one refill formula, and a sliding window that remembers timestamps. The distributed version of the same problem is [[distributed-rate-limiter]].

---

## The one formula behind token bucket

```text
refillRate = capacity / window
newTokens  = oldTokens + (timePassed * refillRate)
tokens     = min(capacity, newTokens)
```

That is the whole maths.
Say the limit is 2 requests per 10 seconds.
Then `refillRate` is 0.2 tokens per second, and after 5 seconds of quiet you have earned 1 token back.

You never run a timer to add tokens.
You work out how many should have arrived the next time someone asks, which is why this is cheap.

---

## Token bucket

```js
class TokenBucket {
  constructor(capacity, windowMs) {
    this.capacity = capacity;
    this.refillRate = capacity / windowMs;   // tokens per millisecond
    this.tokens = capacity;                  // start full
    this.lastRefillTime = Date.now();
  }

  allow() {
    const now = Date.now();
    const elapsed = now - this.lastRefillTime;

    this.tokens = Math.min(this.capacity, this.tokens + elapsed * this.refillRate);
    this.lastRefillTime = now;

    if (this.tokens >= 1) {
      this.tokens -= 1;
      return true;
    }

    return false;
  }
}

const limiter = new TokenBucket(2, 10_000);   // 2 requests per 10 seconds
```

---

## Sliding window

```js
class SlidingWindowRateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.timestamps = [];
  }

  allow() {
    const now = Date.now();

    while (this.timestamps.length && this.timestamps[0] <= now - this.windowMs) {
      this.timestamps.shift();
    }

    if (this.timestamps.length < this.limit) {
      this.timestamps.push(now);
      return true;
    }

    return false;
  }
}
```

This one is strict.
Every request is remembered, every window is checked against real timestamps, and there is no smoothing or averaging.
If 2 requests happened in the last 10 seconds, the third is rejected, always.

---

## Which one, and why

| | Token bucket | Sliding window |
| --- | --- | --- |
| Guarantees | an average rate | a strict rate |
| Bursts | allowed | not allowed |
| State per key | two numbers | one timestamp per request, so O(N) |
| Based on | maths over elapsed time | a list of timestamps |
| Distributed | easy, two fields in Redis | needs a shared store and trimming |

> [!tip] The sentence that separates them
> Token bucket asks "how much permission has time earned me?". Sliding window asks "how many requests actually happened recently?".

Token bucket wins in most production systems because the state is constant per user and bursts are usually fine.
Sliding window wins when the limit is a promise you cannot break, for example a paid quota.

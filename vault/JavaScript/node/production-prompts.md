# Node Production Prompts

> [!tldr]
> Six interview prompts phrased the way an interviewer phrases them, with what they are silently evaluating and the implementation to write.

---

## 1. LRU cache with TTL

**The prompt.** Design an in memory LRU cache supporting `get` and `put`, where each entry expires after a configurable [[ttl|TTL]].

**What they are evaluating.** `get` and `put` must be constant time. Expired keys must not be returned. The cache evicts the least recently used item when over capacity. Single process, no Redis.

**Where it shows up.** Caching database queries inside an API, feature flag or config caching, avoiding repeated calls to downstream services.

**The approach to say out loud.** Use a `Map` to maintain insertion order, refresh key order on access, evict lazily on `get` for TTL, and evict the oldest key on capacity.

The implementation is in [[lru-and-min-stack]].

---

## 2. Concurrency limiter with retries

**The prompt.** Run async tasks but limit concurrency to N. Failed tasks retry up to R times.

**What they are evaluating.** Maximum N concurrent executions, retry only on failure, no promise leaks, and execution order does not matter.

**Where it shows up.** Calling third party APIs with rate limits, background workers, batch jobs.

**The approach.** Maintain a queue, track the active count, retry with recursion, and resolve when everything completes.

```js
function concurrencyLimiter(tasks, limit, retries = 0) {
  let index = 0;
  let active = 0;
  const results = [];

  return new Promise((resolve, reject) => {
    function runNext() {
      if (index === tasks.length && active === 0) {
        return resolve(results);
      }

      while (active < limit && index < tasks.length) {
        const current = index++;
        active++;

        execute(tasks[current], retries)
          .then(res => results[current] = res)
          .catch(err => results[current] = err)
          .finally(() => {
            active--;
            runNext();
          });
      }
    }

    function execute(task, retriesLeft) {
      return task().catch(err => {
        if (retriesLeft > 0) {
          return execute(task, retriesLeft - 1);
        }
        throw err;
      });
    }

    runNext();
  });
}
```

The simpler pool without retries is in [[timers-and-concurrency]].

---

## 3. Sliding window rate limiter

**The prompt.** Allow N requests per user per minute.

**What they are evaluating.** Per user isolation, time based eviction, memory efficiency, single instance with no Redis.

**Where it shows up.** Preventing API abuse, protecting login endpoints, avoiding denial of service amplification.

**The approach.** Store timestamps per user, remove expired ones, reject if the count exceeds the limit.

```js
class RateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.store = new Map();
  }

  allow(userId) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    const timestamps = this.store.get(userId) || [];
    while (timestamps.length && timestamps[0] < windowStart) {
      timestamps.shift();
    }

    if (timestamps.length >= this.limit) return false;

    timestamps.push(now);
    this.store.set(userId, timestamps);
    return true;
  }
}
```

The distributed version, and why it needs a Lua script, is in [[campaign-messaging-engine]].

---

## 4. Job queue with a worker

**The prompt.** A basic job queue with background workers and retry support.

**What they are evaluating.** FIFO order, retry on failure, worker isolation, no external libraries.

**Where it shows up.** Email sending, PDF generation, video processing.

```js
class JobQueue {
  constructor() {
    this.queue = [];
  }

  add(job, retries = 3) {
    this.queue.push({ job, retries });
  }

  async process() {
    while (this.queue.length) {
      const { job, retries } = this.queue.shift();
      try {
        await job();
      } catch (e) {
        if (retries > 0) {
          this.queue.push({ job, retries: retries - 1 });
        }
      }
    }
  }
}
```

Note the retry pushes to the back, so a failing job does not block the queue. That is the in process version of the retry topic idea in [[polling-and-pausing]].

---

## 5. Request deduplication, singleflight

**The prompt.** Multiple requests ask for the same resource simultaneously. Ensure only one actual fetch happens.

**What they are evaluating.** Deduplicating in flight requests, all callers getting the same result, cleanup on failure.

**Where it shows up.** Cache miss database queries, external API calls, config fetching.

**The approach.** A map of in flight promises. Return the existing promise if present, and clean up on completion.

```js
class RequestDeduplicator {
  constructor() {
    this.inFlight = new Map();
  }

  async fetch(key, fn) {
    if (this.inFlight.has(key)) {
      return this.inFlight.get(key);
    }

    const promise = fn()
      .finally(() => this.inFlight.delete(key));

    this.inFlight.set(key, promise);
    return promise;
  }
}
```

> [!tip] This is the same pattern as the OAuth refresh manager
> [[oauth-token-lifecycle]] uses exactly this to stop 100 concurrent 401s becoming 100 refresh calls. It is also the in process answer to the [[thundering-herd|cache stampede]] in [[caching-problems]].

---

## 6. Graceful shutdown

**The prompt.** Ensure a server shuts down gracefully without dropping requests.

**What they are evaluating.** Stop accepting new requests, finish in flight ones, close database connections, handle `SIGTERM` and `SIGINT`.

**Where it shows up.** Kubernetes pod termination, autoscaling events, deployments.

**The approach.** Track active requests, stop the server accepting new connections, and force exit after a timeout.

```js
let activeRequests = 0;
let shuttingDown = false;

app.use((req, res, next) => {
  if (shuttingDown) {
    res.set('Connection', 'close');
    return res.status(503).send('Server is shutting down');
  }

  activeRequests++;
  res.on('finish', () => activeRequests--);
  next();
});

const server = app.listen(3000);

function shutdown(signal) {
  console.log(`${signal} received, shutting down`);
  shuttingDown = true;

  // Stop accepting new connections
  server.close(async () => {
    await db.close();
    process.exit(0);
  });

  // Force exit if in-flight requests do not drain in time
  setTimeout(() => {
    console.error(`Forcing exit with ${activeRequests} requests still active`);
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

> [!warning] Why the timeout matters
> `server.close()` waits for existing connections to end. A keep alive connection that never sends another request will hold the process open forever. The forced exit is what makes the pod actually terminate inside Kubernetes' grace period.

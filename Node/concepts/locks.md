# Locks

> [!tldr]
> Three places to stop two things happening at once: inside one process with a mutex, across processes with a Redis lock, and inside the database with a table lock.

---

## Mutex, inside one process

Only one task holds the lock. The rest queue up.

```js
const { Mutex } = require('async-mutex');

const mutex = new Mutex();
let sharedResource = 0;

async function criticalSection(taskId) {
  const release = await mutex.acquire();   // waits here if someone else holds it
  try {
    sharedResource++;
    await doWork();
  } finally {
    release();                             // always, even if doWork throws
  }
}
```

The order is the thing to remember: task 1 acquires, tasks 2 and 3 wait in a queue the library keeps, and each release lets exactly one more through.

> [!warning] The release has to be in a finally block
> If the work throws and you release only on the happy path, the lock is held forever and every other task waits for a task that has already died.

Note that a mutex only helps inside one process. Two Node instances behind a load balancer each get their own, so it protects nothing.

---

## Redis lock, across processes

For "only one instance of this service should do this", a distributed lock in Redis. The Redlock algorithm is the usual choice, and the numbers you pass it are the whole design.

| Setting | Means |
| --- | --- |
| `lock ttl` | how long you expect to hold the lock. Released earlier if the work finishes earlier |
| `retryDelay` | minimum time you expect to wait before the lock frees up |
| `retryCount` | how many times to retry, default 10 |
| `automaticExtensionThreshold` | how much time must be left before the lock is extended automatically |

Two derived numbers matter more than any single setting:

- **Longest the lock can be held**: `ttl + (retryCount - 1) * automaticExtensionThreshold`
- **Longest another process will wait**: `retryDelay * retryCount`

> [!tip] Keep the waiting shorter than the holding
> If another process gives up before the holder can possibly finish, you get spurious failures under normal load. With a 1000ms ttl, 250ms extension threshold and 10 retries, the lock can be held for 3250ms, so a 320ms retry delay across 10 retries waits 3200ms, just inside it.

The pattern around the lock matters as much as the lock:

1. Check the cache. If the value is there, return it and never take the lock.
2. Take the lock.
3. **Check the cache again.** Someone else may have filled it while you waited, and this second check is what stops a queue of waiters all doing the same expensive work.
4. Do the work, write the cache, release.

Have a fallback for when Redis itself is the thing that failed. Going straight to the source of truth is slower but correct, and better than an error.

---

## Table lock, inside the database

```sql
LOCK TABLE my_schema.my_table IN EXCLUSIVE MODE NOWAIT
```

Run inside a transaction, and the lock is tied to that transaction.

| | |
| --- | --- |
| **Released when** | the transaction commits or rolls back, or the session ends, including a crash |
| **`NOWAIT`** | fail immediately if someone else holds the lock, instead of waiting. A deadlock guard |
| **You unlock it by** | ending the transaction. There is no unlock statement |

That last row is the difference from a mutex. An application lock is something you must remember to release. A database lock releases itself, because its lifetime is the transaction's lifetime.

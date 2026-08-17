# Private, Static, and When You Need a Lock

> [!tldr]
> Synchronous code never needs a lock. Async code absolutely does, because every `await` is a place another request can sneak in.

---

## `private` against `static`

They answer two different questions.

| Keyword | What it controls | The question |
| --- | --- | --- |
| `private` | visibility | who can see or touch this? Only the class inside. |
| `static` | ownership | where does this live? On the class itself, not instances. |

When a variable is not static, it belongs to the instance. You need `new` to create it.

When you make something static, it belongs to the class. It exists in memory the moment the program loads, even with zero objects created.

A **singleton** needs both. `private` stops anyone outside reaching the instance. `static` puts the instance on the class, so you can get at it without first creating an object.

---

## Synchronous code needs no locks

In Java, C# or C++, multiple threads execute at the same time. If two threads change the same variable in the same millisecond, data corrupts. A lock forces them into a single file line.

In TypeScript this cannot happen. Only one piece of synchronous code ever runs at a time.

```ts
let counter = 0;

function increment() {
    // No lock needed here.
    // No other thread can interrupt this exact line.
    counter++;
}
```

No lock is needed. No other thread can interrupt this line.

---

## Async code does need logical locks

The runtime is single-threaded, but highly concurrent because of `async`/`await`.

Every `await` pauses the current function and yields control back to the event loop. Other code can run. This creates async race conditions.

```ts
let accountBalance = 100;

async function withdraw(amount: number) {
    if (accountBalance >= amount) {
        // We hit an await. Control yields to the rest of the app.
        // If the user double clicks withdraw, a second request
        // can sneak in right here.
        await performFraudCheckApiCall();
        accountBalance -= amount;

        console.log(`Success! New balance: ${accountBalance}`);
    } else {
        console.log("Insufficient funds");
    }
}
```

If a user double-clicks and triggers `withdraw(100)` twice in rapid succession:

1. Call A checks the balance: 100 is at least 100. Passes. Hits `await` and pauses.
2. Call B starts. Checks the balance: still 100. Passes. Hits `await` and pauses.
3. Call A resumes and subtracts 100. Balance is 0.
4. Call B resumes and subtracts 100. Balance is -100.

### The fix: a mutex

```ts
import { Mutex } from 'async-mutex';

const mutex = new Mutex();

async function safeWithdraw(amount: number) {
    // Locks out any other call to safeWithdraw until release() is called
    const release = await mutex.acquire();

    try {
        if (accountBalance >= amount) {
            await performFraudCheckApiCall();
            accountBalance -= amount;
        }
    } finally {
        // Unlocks, allowing the next call in line to proceed
        release();
    }
}
```

The mutex locks out any other call to `safeWithdraw` until `release()` runs.

---

## True multithreading

Heavy CPU computation can use worker threads or web workers in the browser. Real separate threads.

If those threads share memory using a `SharedArrayBuffer`, they can step on each other like in C++. JavaScript provides the `Atomics` object for traditional lock operations: `Atomics.wait()` and `Atomics.notify()` to synchronise memory access.

See [[worker-threads]] for when to use them.

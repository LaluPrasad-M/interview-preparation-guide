# Private, Static, and When You Need a Lock

> [!tldr]
> Synchronous code never needs a lock. Async code absolutely does, because every `await` is a place another request can sneak in.

---

## `private` against `static`

They do two completely different jobs, answering two different questions.

| Keyword | What it controls | The question it answers |
| --- | --- | --- |
| `private` | visibility | who can see or touch this variable? Only the inside of this class |
| `static` | ownership | where does this variable live? On the class itself, not on the created objects |

**What `static` actually does.** When a variable or method is not static, it belongs to the instance. You have to create an object with `new` before it exists in memory.

When you make something static, it belongs to the class itself. It exists in memory the moment the program loads, even with zero objects created.

That is why a [[singleton]] needs both: `private` so nobody outside can reach the instance, and `static` so the instance lives on the class rather than on an object you have not created yet.

---

## Synchronous code needs no locks

In Java, C# or C++, multiple threads execute at the exact same time. If two threads change the same variable in the same millisecond, your data corrupts, so you use a lock to force them into a single file line.

In TypeScript this cannot happen. Only one piece of synchronous code ever runs at a time.

```ts
let counter = 0;

function increment() {
    // No lock needed here.
    // No other thread can interrupt this exact line.
    counter++;
}
```

---

## Async code does need logical locks

While the runtime is single threaded, it is highly concurrent because of `async`/`await`.

Whenever your code hits an `await`, the current function pauses, yields control back to the event loop, and lets other code run. That creates async race conditions.

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

If a user double clicks and triggers `withdraw(100)` twice in rapid succession:

1. Call A checks the balance, 100 is at least 100, passes, hits `await` and pauses.
2. Call B starts, checks the balance which is still 100, passes, hits `await` and pauses.
3. Call A resumes and subtracts 100. The balance is 0.
4. Call B resumes and subtracts 100. The balance is -100.

### The fix, a mutex

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

---

## True multithreading

If you are doing heavy CPU computation with worker threads, or web workers in the browser, you can spin up real separate threads.

If those threads share memory using a `SharedArrayBuffer`, they can step on each other exactly like in C++. In that specific scenario, JavaScript provides the `Atomics` object, which gives traditional true lock operations such as `Atomics.wait()` and `Atomics.notify()` to synchronise memory access.

See [[worker-threads]] for when to reach for them at all.

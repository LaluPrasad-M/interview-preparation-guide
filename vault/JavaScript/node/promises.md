# Promises

> [!tldr]
> Four combinators, and one rule about errors: an `await` that rejects behaves exactly like a `throw`, so `try` and `catch` work normally.

Two helpers used throughout, the same pair as [[puzzles-promises]]. One resolves, one rejects, and they are named differently so no snippet is ambiguous about which it means:

```js
function fetchData(t = 1000, value = 'Data') {
  return new Promise(resolve => setTimeout(resolve, t, value));
}

function failData(t = 1000) {
  return new Promise((_, reject) => setTimeout(reject, t, new Error('Error occurred')));
}
```

---

## The combinators

| | Resolves when | Rejects when |
| --- | --- | --- |
| `Promise.all` | every promise resolves | the first one rejects, immediately, without waiting for the rest |
| `Promise.allSettled` | all of them finish, however they finish | never |
| `Promise.race` | the first one settles, resolved or rejected | the first one settles, if that was a rejection |
| `Promise.any` | the first one resolves | all of them reject |

`Promise.all` also accepts plain values, which it treats as already resolved:

```js
const slowPromise = fetchData(1000, 'foo');
Promise.all([Promise.resolve(3), 42, slowPromise]).then(console.log);
// [3, 42, 'foo']
```

---

## all vs allSettled

```js
try {
  await Promise.all([failData(1000), failData(5000)]);
} catch (error) {
  console.log(error.message); // fires at 1000ms, not 5000ms
}
```

`Promise.all` gives up the moment anything fails. That is what you want when you need all the results, and wrong when you want to know which ones worked:

```js
const results = await Promise.allSettled([fetchData(1000, 'Resolved Data'), failData(500)]);

results.forEach((result, index) => {
  if (result.status === 'fulfilled') console.log(index, 'Data:', result.value);
  else console.log(index, 'Error:', result.reason.message);
});
```

> [!warning] allSettled never rejects
> Wrapping it in `try` and `catch` is pointless, and the `catch` block is dead code. Every outcome arrives inside the results array instead.

---

## Errors

```js
async function example() {
  try {
    const data = await failData();      // rejects
    console.log(data);                  // skipped
  } catch (error) {
    console.log(error.message);
    throw new Error('Another error');   // replaces the original
  } finally {
    console.log('Finally');             // runs either way
  }
  console.log('End');                   // never reached, we threw
}

example().catch(error => console.log(error.message));
```

Three things worth holding on to. `finally` runs whether you returned, threw, or fell through. Throwing inside `catch` means the caller has to handle it, so the `async` function needs a `.catch` at the call site. And a `return` inside `catch` skips the rest of the function but still runs `finally`.

---

## Not awaiting is a decision

```js
async function example() {
  console.log('Start');
  fetchData().then(console.log).finally(() => console.log('Finally'));
  console.log('End');   // prints before either of the above
}
```

Leaving off `await` means the function does not wait. Sometimes that is what you want. Usually it means an unhandled rejection later, and Node has terminated the process on those since version 15.

---

## Nested promises flatten themselves

```js
function chainedPromises() {
  return new Promise(res1 =>
    res1(new Promise(res2 =>
      res2(new Promise(res3 => setTimeout(res3, 1000, 'Data'))))));
}

console.log(await chainedPromises());  // 'Data'
```

Three promises deep, and one `await` unwraps all of it. Resolving a promise with another promise makes the outer one wait for the inner one, however many layers there are. You never get a promise of a promise back.

---

## The cooking example

> [!example]- Making a meal, as a promise chain
> Every step is a promise, and some steps are built out of smaller steps. Abridged: `boilRice`, `washCereals`, `boilCereals`, `cookCurry` and `eatFood` all follow the same shape as `washRice` and are left out.
>
> ```js
> function washRice(value) {
>   console.log('starting washRice 1');
>   return new Promise(function (resolve) {
>     console.log('starting washRice');
>     resolve('Washed Rice');
>     console.log('After Cooking Rice');   // still runs, resolve does not return
>   });
>   console.log('ending washRice 1');      // never runs, it is after a return
> }
>
> function cookRice(value) {
>   return new Promise(function (resolve) {
>     washRice()
>       .then(boilRice)
>       .then(function (value) {
>         resolve('Rice Cooked');
>       });
>   });
> }
>
> function cookFood(value) {
>   return new Promise(function (resolve) {
>     cookRice()
>       .then(cookCurry)
>       .then(function (value) {
>         resolve('Food Cooked');
>       });
>   });
> }
>
> console.log('Wash Hands before Food');
> cookFood()
>   .then(eatFood)
>   .then(value => console.log('Wash Hands after Food'));
> console.log('END Of Process');
> ```
>
> Three lessons hide in the log order:
>
> 1. `END Of Process` prints almost immediately, long before the food is cooked. The chain was only started, not waited for.
> 2. `resolve()` is not `return`. The line after it still runs, which is why `After Cooking Rice` appears.
> 3. Code after a `return` never runs, so `ending washRice 1` prints never.
>
> The nesting also shows why `async` and `await` won. The same logic written with `await` is six flat lines with no `new Promise` at all.

---

## Writing a cancellable promise

A promise cannot be cancelled once created, so you wrap it with an external control mechanism.

**The pieces.** A controller holding the cancellable state, a signal that flips the flag or fires an event, and a wrapper encapsulating the promise plus that control. The wrapper polls the signal, and on abort it rejects and cleans up timers, listeners and in flight requests.

```js
class CancellableTask {
  run(signal) {
    return new Promise((resolve, reject) => {
      if (signal.aborted) {
        return reject(new Error('Already aborted'));
      }

      const timer = setInterval(() => {
        console.log('Working, waiting for termination');
      }, 1000);

      signal.addEventListener('abort', () => {
        clearInterval(timer);
        reject(new Error('Aborted by caller'));
      });
    });
  }
}

const controller = new AbortController();
const task = new CancellableTask();

task.run(controller.signal).then(console.log).catch(console.error);

setTimeout(() => controller.abort(), 5000);
```

> [!warning] The cleanup is the point
> Rejecting alone leaves the interval running and the process alive. Every resource the task opened must be released in the abort handler.

---

## Writing a Promise from scratch

The theory before the code.

1. It needs state management: pending, resolved or rejected.
2. It needs callback queues, because `then` can be called before the value arrives.
3. `resolve()` changes state and drains the queued success callbacks.
4. `reject()` changes state and drains the queued failure callbacks.
5. `then()` either executes immediately or stores the callback, depending on state.
6. `then()` must return another promise, which is what makes chaining work.

```js
class CustomPromise {
  constructor(fn) {
    this.state = "PENDING";
    this.value = undefined;
    this.error = undefined;
    this.onFulfilled = [];
    this.onRejected = [];

    const resolve = (value) => {
      if (this.state === 'PENDING') {
        this.state = 'RESOLVED';
        this.value = value;
        this.onFulfilled.forEach(fn => fn(value));
      }
    };

    const reject = (err) => {
      if (this.state === 'PENDING') {
        this.state = 'REJECTED';
        this.error = err;
        this.onRejected.forEach(fn => fn(err));
      }
    };

    try {
      fn(resolve, reject);
    } catch (e) {
      reject(e);
    }
  }

  then(cb) {
    return new CustomPromise((resolve, reject) => {
      const handle = () => {
        try {
          resolve(cb(this.value));
        } catch (e) {
          reject(e);
        }
      };

      if (this.state === 'RESOLVED') {
        handle();
      } else {
        this.onFulfilled.push(handle);
      }
    });
  }

  catch(cb) {
    return new CustomPromise((resolve, reject) => {
      const handle = () => {
        try {
          resolve(cb(this.error));
        } catch (e) {
          reject(e);
        }
      };

      if (this.state === 'REJECTED') {
        handle();
      } else {
        this.onRejected.push(handle);
      }
    });
  }
}

const p = new CustomPromise((res) => res("23"));

p.then(val => {
  console.log(val);
  return val; // return it so the next then receives it
}).then(console.log);
```

Verified on Node v22.16.0, printing `23` twice.

> [!question] How does a shared prototype method know which resolve to call?
> The methods are shared via the prototype, but `resolve` and `reject` are closures created inside each constructor call, capturing that instance. `then` never touches them directly. It reads `this.state` and `this.value` off the specific object, and creates a brand new promise with its own pair.

> [!warning] What this version does not do
> The real specification defers every callback to the microtask queue, so `then` is never synchronous. This one calls `handle()` immediately when already resolved. It also does not handle a thenable being returned from a callback. Name both out loud if you write this in an interview.

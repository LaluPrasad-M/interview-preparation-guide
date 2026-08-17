# Promises, Advanced Patterns

> [!tldr]
> The cooking example walkthrough, implementing cancellable promises, and writing a Promise from scratch with state management and callback queues.

Part of [[promises]].

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

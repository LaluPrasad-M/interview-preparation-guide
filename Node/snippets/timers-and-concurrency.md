# Timers and Concurrency Helpers

> [!tldr]
> The small utilities interviewers ask you to write from scratch: sleep, a cancellable timer, a timeout wrapper, progress reporting, and a concurrency pool.

---

## Sleep

```js
async function sleep(millis) {
  await new Promise(res => setTimeout(res, millis));
}
```

The whole trick is that `setTimeout` takes the `resolve` function as its callback, so the promise settles when the timer fires.

---

## Cancellable timer

```js
const cancellable = function (fn, args, t) {
  const timer = setTimeout(fn, t, ...args);
  return () => clearTimeout(timer);      // the returned function is the cancel
};

const cancel = cancellable(name => console.log(`Hello ${name}`), ['Alice'], 1000);
await sleep(500);
cancel();                                 // nothing prints
```

Same shape for an interval, with `setInterval` and `clearInterval`. The pattern is: schedule, then hand back a closure that knows the handle.

---

## Timeout wrapper

Wrap a function so it rejects if it takes too long.

```js
const timeLimit = function (fn, t) {
  return async function (...args) {
    return new Promise(async (resolve, reject) => {
      const timer = setTimeout(() => reject('Time Limit Exceeded'), t);
      try {
        resolve(await fn.apply(this, args));
      } catch (err) {
        reject(err);
      } finally {
        clearTimeout(timer);   // stop the timer either way
      }
    });
  };
};

const limited = timeLimit(t => new Promise(res => setTimeout(res, t)), 100);
limited(150).catch(console.log); // 'Time Limit Exceeded' at 100ms
```

Two promises race here, the real work and the timer, and whichever settles first wins. The `finally` matters: without `clearTimeout`, the timer keeps the process alive for its full duration even after the work finished.

---

## Progress while waiting

Attach a `then` to each promise so you can count them as they land.

```js
const allWithProgress = async (promises, progress) =>
  Promise.all(promises.map(promise =>
    promise.then(result => {
      progress(result);
      return result;             // pass it along so Promise.all still gets it
    })
  ));
```

The `return result` is the part people forget. Without it the callback returns `undefined` and `Promise.all` resolves to an array of nothing.

---

## Concurrency pool

Run at most `m` of `n` tasks at once, starting the next one as soon as any finishes.

```js
const promisePool = async (tasks, concurrency) => {
  let index = 0;
  const results = [];

  const worker = async () => {
    while (index < tasks.length) {
      const current = index++;          // claim a slot before awaiting
      results[current] = await tasks[current]();
    }
  };

  await Promise.all(Array(concurrency).fill().map(worker));
  return results;
};
```

The design in one line: start exactly `concurrency` workers, and let each one pull the next task off a shared index until the list is empty.

> [!warning] Claim the index before you await
> `index++` has to happen before the `await`, or two workers read the same value and run the same task twice. Writing into `results[current]` rather than pushing also keeps the results in the original order.

---

## Array methods, written out

Asked often, because they show whether you understand callbacks.

```js
var reduce = function (nums, fn, init) {
  for (const num of nums) init = fn(init, num);
  return init;
};

var filter = function (arr, fn) {
  const res = [];
  arr.forEach((e, i) => { if (fn(e, i)) res.push(e); });
  return res;
};

var map = function (arr, fn) {
  const res = [];
  arr.forEach((e, i) => res.push(fn(e, i)));
  return res;
};
```

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

The pattern is: schedule, then hand back a closure that knows the handle.

The interval version is nearly the same, with one line that changes its behaviour:

```js
const cancellable = function (fn, args, t) {
  fn.apply(this, args);                          // fire once immediately
  const intervalTimer = setInterval(fn, t, ...args);
  return () => clearInterval(intervalTimer);
};
```

> [!warning] That first call is the difference
> `setInterval` alone waits `t` before its first run. Calling `fn` up front means the caller sees a result straight away and then every `t` after that. Verified: a 50ms interval cancelled at 170ms fires four times with the leading call and three without it. If a question says "call it now and then every second", that line is what it is testing.

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

Two promises race here: the real work and the timer. Whichever settles first wins. The `finally` matters. Without `clearTimeout`, the timer keeps the process alive for its full duration even after the work finishes.

---

## Progress while waiting

Attach a `then` to each promise so you can count them as they land.

```js
const allWithProgress = async (promises, progress) => {
  let complete = 0;
  return Promise.all(promises.map(promise =>
    promise.then(result => {
      complete++;
      const percentComplete = (complete / promises.length) * 100;
      progress(percentComplete.toFixed(2));
      return result;             // pass it along so Promise.all still gets it
    })
  ));
};
```

The `return result` is the part people forget. Without it the callback returns `undefined` and `Promise.all` resolves to an array of nothing.

The same thing without `Promise.all`, which is really a `Promise.all` implementation:

```js
const allWithProgress = async (promises, progress) =>
  new Promise((resolve, reject) => {
    const results = [];
    for (const promise of promises) {
      promise.then(result => {
        results.push(result);
        progress(((results.length / promises.length) * 100).toFixed(2));
        if (results.length === promises.length) resolve(results);
      });
    }
  });
```

Both versions take the same `progress(percent)` callback, so they are interchangeable. Writing the second one out shows what `Promise.all` actually does. It attaches a handler to every promise, counts the completions, and resolves when the count matches.

> [!warning] This version loses the input order
> Results are pushed as they finish, so a slow first promise ends up last in the array. The `Promise.all` version keeps the original order.
>
> To fix it you need the index, which `for...of` over the array does not give you:
>
> ```js
> for (const [index, promise] of promises.entries()) {
>   promise.then(result => { results[index] = result; /* ... */ });
> }
> ```
>
> Counting completions then has to be its own variable, because `results.length` jumps to the highest index written rather than the number filled in. Nothing here handles a rejection either, so one failure means it never resolves.

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

This is a rewrite rather than the original. The notebook version recursed inside a `new Promise` and logged `Progress: n%` and `Completed task n` after each task, which is worth knowing about, but it pushed results in completion order so the returned array did not match the input order.

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

The original `filter` used `for...in` instead, which is worth seeing because of the conversion it needs:

```js
var filter = function (arr, fn) {
  const res = [];
  for (const i in arr) {
    if (fn(arr[i], Number(i))) {   // Number(i), because for...in hands you '0' not 0
      res.push(arr[i]);
    }
  }
  return res;
};
```

`for...in` gives string keys, so the index passed to the callback needs converting or a predicate like `(e, i) => i % 2 === 0` silently misbehaves. See [[iteration]].

---

Sources for this note: the [LeetCode 30 Days of JavaScript](https://leetcode.com/studyplan/30-days-of-javascript) study plan.

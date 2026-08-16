# Why Middleware Uses Recursion

> [!tldr]
> A loop cannot work, because `next()` may be called later. That one sentence is the whole answer.

---

## What later means

In JavaScript, functions do not always run immediately.

```js
setTimeout(() => {
  console.log('later');
}, 1000);
```

The callback runs after the current call stack finishes. Middleware can do the same thing.

```js
const asyncMiddleware = (req, res, next) => {
  setTimeout(() => {
    console.log('Async work done');
    next(); // called LATER
  }, 1000);
};
```

`next()` is delayed. Nothing about the middleware signature guarantees it is called synchronously.

---

## Why a loop breaks

```js
// The naive attempt
for (let i = 0; i < middlewares.length; i++) {
  middlewares[i](req, res, next);
}
```

The loop runs immediately, so all middlewares are invoked synchronously. `next()` is ignored as a control signal, and the async middleware has not finished when the next one starts.

```text
loop start
middleware 1
middleware 2
middleware 3
loop end
(the next() calls happen later, but too late)
```

---

## Why recursion works

```js
const execute = (index) => {
  if (index >= middlewares.length) return;
  middlewares[index](req, res, () => {
    execute(index + 1);
  });
};

execute(0);
```

The next middleware runs only when `next()` is called. That is the point: `next()` becomes the continuation, not a hint.

---

## The proof

```js
const middlewares = [
  (req, res, next) => { console.log('A'); next(); },
  (req, res, next) => { setTimeout(() => { console.log('B (async)'); next(); }, 50); },
  (req, res, next) => { console.log('C'); }
];
```

Run with the loop and you get:

```text
A
C
B (async)
```

Run with the recursion and you get:

```text
A
B (async)
C
```

Verified on Node v22.16.0. The loop reorders your pipeline the moment any middleware does async work, which is most of them: auth lookups, body parsing, database calls.

---

## Why this gets asked

It is a small question that tests whether you understand that `next()` is a continuation rather than a return value, and that async work cannot be sequenced by a synchronous loop. The same shape appears in [[production-prompts]] as the retry recursion inside the concurrency limiter.

# Utility Polyfills, Function Utilities

> [!tldr]
> Five function utility polyfills showing higher-order function patterns: once, memoize, debounce, slice, and splice.

Part of [[utility-polyfills]].

---

## once

```js
function once(fn) {
  let called = false;
  let result;

  return function (...args) {
    if (!called) {
      called = true;
      result = fn.apply(this, args);
    }
    return result;
  };
}

const init = once(x => x * 2);
init(10); // 20
init(50); // 20
```

**The mistakes.** Not forwarding arguments, not preserving `this`, and not caching the return value.

**Key points.** It must cache the result, forward args and preserve `this`. It is async safe, because the promise itself is what gets cached.

---

## memoize

```js
function memoize(fn) {
  const cache = new Map();

  return function (...args) {
    const key = JSON.stringify(args);

    if (cache.has(key)) {
      return cache.get(key);
    }

    const result = fn.apply(this, args);
    cache.set(key, result);
    return result;
  };
}

const add = memoize((a, b) => a + b);
add(2, 3); // computed
add(2, 3); // cached
```

**Key points.** Cache the value or the promise, and caching the promise gives you concurrency safety, which is the same idea as singleflight in [[production-prompts]]. `JSON.stringify` is an imperfect key for objects, because key order matters.

---

## debounce

```js
function debounce(fn, delay) {
  let timerId;

  return function (...args) {
    clearTimeout(timerId);
    timerId = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}

const search = debounce(q => console.log(q), 300);
search("r");
search("ra");
search("rahul");
// logs only "rahul"
```

**The mistake.** Forgetting `clearTimeout`. Without it, this is not debounce at all, it is just a delay.

**Key point.** Debounce waits for silence.

---

## slice

```js
function mySlice(array, start = 0, end = array.length) {
  const result = [];

  for (let i = start; i < end && i < array.length; i++) {
    result.push(array[i]);
  }

  return result;
}

mySlice([1, 2, 3, 4], 1, 3);
// [2, 3]
```

**Key points.** Non mutating, returns a shallow copy, and used heavily for immutability. People confuse it with `splice` and assume it mutates. It does not.

---

## splice

```js
function mySplice(array, start, deleteCount, ...items) {
  const removed = array.slice(start, start + deleteCount);
  array.splice(start, deleteCount, ...items);
  return removed;
}

const arr = [1, 2, 3, 4];
arr.splice(1, 2, 9, 10);
// arr becomes [1, 9, 10, 4]
```

In an interview, explaining the behaviour beats writing the full polyfill.

**Key points.** It mutates the original array, it can delete, insert or replace, and it returns the removed elements.

---

> [!warning] The rule that spans all of them
> Any higher order function must forward `this` and the arguments with `fn.apply(this, args)`. Missing that is a red flag.

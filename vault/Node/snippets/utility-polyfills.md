# Utility Function Polyfills

> [!tldr]
> Ten utilities interviewers ask you to write from scratch, each with the mistake that actually gets made.

> [!warning] The rule that spans all of them
> Any higher order function must forward `this` and the arguments with `fn.apply(this, args)`. Missing that is a red flag.

---

## map

```js
function myMap(array, callback) {
  const result = [];

  for (let i = 0; i < array.length; i++) {
    result.push(callback(array[i], i, array));
  }

  return result;
}

myMap([1, 2, 3], (value, index) => value * index);
// [0, 2, 6]
```

**The mistake.** Forgetting the callback contract, which is `(value, index, array)`, not just the value.

**Key points.** It transforms values, always returns a new array, and never mutates the input.

---

## filter

```js
function myFilter(array, callback) {
  const result = [];

  for (let i = 0; i < array.length; i++) {
    if (callback(array[i], i, array)) {
      result.push(array[i]);
    }
  }

  return result;
}

myFilter([1, 2, 3, 4], n => n % 2 === 0);
// [2, 4]
```

**The mistake.** Treating the callback as a transformer. It returns a boolean and acts as a gatekeeper.

**Key points.** Filter returns a subset, not transformed values. Never push `callback(...)`, push the element.

---

## reduce

```js
function myReduce(array, callback, initialValue) {
  let acc;
  let startIndex;

  if (initialValue !== undefined) {
    acc = initialValue;
    startIndex = 0;
  } else {
    acc = array[0];
    startIndex = 1;
  }

  for (let i = startIndex; i < array.length; i++) {
    acc = callback(acc, array[i], i, array);
  }

  return acc;
}

myReduce([1, 2, 3], (sum, n) => sum + n, 0);
// 6
```

**The mistake.** Forgetting that `initialValue` is optional, and not handling the `acc = array[0]` case.

**Key points.** The callback is `(accumulator, current, index, array)`. It returns one value, in constant space. An empty array with no initial value throws, which is the native behaviour.

---

## compact

```js
function compact(array) {
  const result = [];

  for (let i = 0; i < array.length; i++) {
    if (array[i]) {
      result.push(array[i]);
    }
  }

  return result;
}

compact([0, 1, false, 2, "", 3]);
// [1, 2, 3]
```

**The mistake.** Overthinking `NaN` with type checks, and accidentally keeping `0`.

**Key points.** It works on truthiness, removing `false`, `0`, `""`, `null`, `undefined` and `NaN`. If `0` is meaningful in your data, this is the wrong utility.

---

## groupBy

```js
function groupBy(array, callback) {
  return array.reduce((acc, value, index) => {
    const key = callback(value, index, array);

    if (!acc[key]) acc[key] = [];
    acc[key].push(value);

    return acc;
  }, {});
}

groupBy([1, 2, 3, 4], n => n % 2 === 0 ? "even" : "odd");
// { odd: [1, 3], even: [2, 4] }
```

**Key points.** The output is an object of arrays. An imperative loop is equally valid, but `reduce` shows the intent more clearly.

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

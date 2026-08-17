# Utility Polyfills, Array Methods

> [!tldr]
> Five array method polyfills showing the callback contract and the patterns behind map, filter, reduce, compact, and groupBy.

Part of [[utility-polyfills]].

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

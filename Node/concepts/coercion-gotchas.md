# Coercion and Other Traps

> [!tldr]
> The output questions people use to catch you out. Almost all of them come from one habit of JavaScript: when types do not match, it converts rather than complains.

---

## Plus is not minus

```js
console.log(5 + '5');   // '55'   plus prefers strings, so 5 becomes '5'
console.log(5 - '5');   // 0      minus has no string meaning, so '5' becomes 5
console.log('5' - '5'); // 0
console.log(5 + + '5'); // 10     the second + converts '5' to 5 first
```

`+` is the only operator that means two things, addition and concatenation. If either side is a string it concatenates. Every other maths operator converts to number.

---

## typeof lies twice

```js
console.log(typeof undefined); // 'undefined'
console.log(typeof null);      // 'object'   a bug from 1995, kept for compatibility
console.log(typeof []);        // 'object'   use Array.isArray instead
console.log(typeof NaN);       // 'number'   the not a number value is a number
```

---

## Numbers

```js
console.log(0.1 + 0.2 === 0.3);  // false, floating point
console.log(Number('10') === 10); // true
console.log(parseInt('11', 2));   // 3, second argument is the base
console.log((10).toString(2));    // '1010'
console.log(2 ** 3);              // 8
```

---

## Sorting

```js
const arr = [1, 9, 5, 3, 0, 14, 8];
arr.sort();             // [0, 1, 14, 3, 5, 8, 9]
arr.sort((a, b) => a - b); // [0, 1, 3, 5, 8, 9, 14]
```

> [!warning] Default sort is alphabetical
> `sort` converts everything to strings unless you pass a comparator, which is why 14 lands between 1 and 3. Also note `sort` mutates the array while `toSorted` returns a new one.

---

## The map parseInt classic

```js
['0', '1', '2', '10', '12'].map(parseInt); // [0, NaN, NaN, 3, 5]
```

`map` passes three arguments, and `parseInt` takes two. So the index becomes the base. `parseInt('1', 1)` is invalid, `parseInt('10', 3)` is 3. Fix it with `.map(Number)` or `.map(s => parseInt(s, 10))`.

---

## Objects compare by identity

```js
console.log([] == []); // false
console.log({} == {}); // false
```

Two separate objects are never equal, however identical they look. Equality on objects compares references.

And the trick built on coercion:

```js
let x = {
  flag: 1,
  toString() { return this.flag++; }
};

if (x == 1 && x == 2 && x == 3) console.log('Hello World!');
```

It prints. Loose `==` calls `toString` each time, and this one returns a different number every call.

---

## Falsy or nullish

```js
const input = '';

console.log(input || 'Default'); // 'Default'
console.log(input ?? 'Default'); // ''
```

| | Falls back on |
| --- | --- |
| `\|\|` | any falsy value: `false`, `0`, `''`, `null`, `undefined`, `NaN` |
| `??` | only `null` and `undefined` |

Use `??` when `0` or an empty string are legitimate values, which is most of the time in real code.

---

## Arrays with holes

```js
const arr = [1, 2, 3];
arr[5] = 6;
console.log(arr.length); // 6, not 4
```

Length is the highest index plus one, not the count of items. The gap holds empty slots, which `forEach` and `map` skip over.

---

## Bonus, from a binary search

`mid = (low + high) / 2` overflows when both are near the maximum integer. Use `mid = low + (high - low) / 2`. Same answer, no overflow.

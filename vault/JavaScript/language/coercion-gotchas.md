# Coercion and Other Traps

> [!tldr]
> The output questions used to catch you out. Most come from one habit: JavaScript converts types rather than throwing an error when types do not match.

---

## Plus is not minus

```js
console.log(5 + '5');   // '55'   plus prefers strings, so 5 becomes '5'
console.log(5 - '5');   // 0      minus has no string meaning, so '5' becomes 5
console.log('5' - '5'); // 0
console.log(5 + + '5'); // 10     the second + converts '5' to 5 first
```

**`+` means two things.** Addition and concatenation. If either side is a string, it concatenates. Every other maths operator converts both sides to number.

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
console.log(0.1 + 0.2 === 0.3);   // false, floating point
console.log(Number('10') === 10); // true
console.log(parseInt('11', 2));   // 3, second argument is the base
console.log((10).toString(2));    // '1010'
console.log(2 ** 3);              // 8
```

---

## Sorting

```js
var arr = [1, 9, 5, 3, 0, 14, 8];

var sortedArr = arr.sort();
console.log(arr);        // [0, 1, 14, 3, 5, 8, 9], the original was mutated
console.log(sortedArr);  // [0, 1, 14, 3, 5, 8, 9], same array

var sortedArr = arr.toSorted();
console.log(arr);        // unchanged
console.log(sortedArr);  // a new array, still sorted alphabetically

var sortedArr = arr.sort((a, b) => a - b);
console.log(arr);        // [0, 1, 3, 5, 8, 9, 14], mutated again
console.log(sortedArr);  // [0, 1, 3, 5, 8, 9, 14], the same array
```

> [!warning] Default sort is alphabetical
> `sort` converts everything to strings unless you pass a comparator, which is why 14 lands between 1 and 3. `sort` also mutates and returns the same array, so `arr` and `sortedArr` are the same object. `toSorted` returns a new one and leaves the original alone.

---

## The map parseInt classic

```js
['0', '1', '2', '10', '12'].map(parseInt); // [0, NaN, NaN, 3, 6]
```

`map` passes three arguments, and `parseInt` takes two, so the index becomes the base. Working through it:

| Call | Result | Why |
| --- | --- | --- |
| `parseInt('0', 0)` | 0 | base 0 means "guess", so decimal |
| `parseInt('1', 1)` | NaN | base 1 does not exist |
| `parseInt('2', 2)` | NaN | binary has no digit 2 |
| `parseInt('10', 3)` | 3 | 1 times 3, plus 0 |
| `parseInt('12', 4)` | 6 | 1 times 4, plus 2 |

Fix it with `.map(Number)` or `.map(s => parseInt(s, 10))`.

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

if (x == 1 && x == 2 && x == 3) {
  console.log('Hello World!');
} else {
  console.log('Goodbye World!');
}
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

Length is the highest index plus one, not the count of items. The gap holds empty slots, which `forEach` and `map` skip over while a plain `for` loop sees `undefined`.

---

## Ternary is falsy too

```js
const input = '';
const result = input ? input : 'Default Value';
console.log(result); // 'Default Value'
```

**Ternary tests truthiness.** Like `||`, it treats `''`, `0` and `NaN` as false. Only `??` narrows that to `null` and `undefined`.

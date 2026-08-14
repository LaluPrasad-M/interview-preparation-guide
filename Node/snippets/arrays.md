# Array Snippets

> [!tldr]
> Creating arrays, changing them, taking them apart. Mostly about what each method returns, which is where the interview questions live.

---

## What the mutating methods return

```js
const a = [1, 2, 3];

a.push(4, 5, 7);   // 6, the new length
a.unshift(-1, 0);  // 8, the new length
a.pop();           // 7, the element removed
a.shift();         // -1, the element removed
```

| Method | Adds or removes at | Returns |
| --- | --- | --- |
| `push` | the end | the new length |
| `unshift` | the start | the new length |
| `pop` | the end | the removed element |
| `shift` | the start | the removed element |

The add methods give you a length, the remove methods give you the item. Mixing that up is a common slip.

---

## Creating arrays

```js
Array(10);                          // [ <10 empty items> ], holes, not undefined
Array(10).keys();                   // Object [Array Iterator] {}, lazy
Array.from(Array(10).keys());       // [0, 1, 2, ..., 9]
Array(24).fill(12);                 // 24 copies of 12

// 2D array, m rows of n falses
Array.from({ length: m }, () => Array(n).fill(false));
```

> [!warning] Never build a grid with fill(Array(n))
> `Array(m).fill(Array(n).fill(false))` gives every row the same array, so setting `grid[0][0]` changes every row at once. `Array.from` with a function runs that function per row, which is what makes each row its own array.

---

## Destructuring

```js
const arr = [1, 2, 3, 4, 5];

const [a, , b] = arr;      // a = 1, b = 3, the gap skips an element
const [first, ...rest] = arr; // first = 1, rest = [2, 3, 4, 5]
```

Spreading into a function is how you get around a function that takes separate arguments:

```js
Math.max(...[1, 2, 3, 4]);  // 4
Math.max([1, 2, 3, 4]);     // NaN, it got one argument that was an array
```

---

## slice vs splice

```js
const arr = [1, 2, 3, 4, 5];

arr.slice(1, 3);       // [2, 3],  arr unchanged
arr.splice(1, 3);      // [2, 3, 4], arr is now [1, 5]
arr.splice(1, 0, 9);   // [], inserts 9 at index 1 without removing anything
```

| | Changes the original | Second argument means | Can insert |
| --- | --- | --- | --- |
| `slice(start, end)` | no | the index to stop before | no |
| `splice(start, count, ...items)` | yes | how many to remove | yes |

One letter apart, opposite behaviour. `slice` copies, `splice` operates.

---

## Reducing

```js
const arr = [1, 2, 3, 4];
arr.reduce((acc, curr) => acc + curr, 0);  // 10
```

The `0` is the starting value. Leave it out on an empty array and it throws, which is why you almost always pass it.

---

## Sorting

```js
const arr = [1, 9, 5, 3, 0, 14, 8];

arr.sort();                 // [0, 1, 14, 3, 5, 8, 9]  alphabetical
arr.sort((a, b) => a - b);  // [0, 1, 3, 5, 8, 9, 14]  numeric
arr.toSorted();             // same ordering rules, but returns a new array
```

See [[coercion-gotchas]] for why the default is alphabetical.

---

## Length is not a count

```js
const arr = [1, 2, 3];
arr[5] = 6;
arr.length;   // 6
```

Length is the highest index plus one. Indexes 3 and 4 are holes, and `map` and `forEach` skip them while a plain `for` loop sees `undefined`.

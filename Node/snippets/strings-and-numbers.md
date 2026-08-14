# String and Number Snippets

> [!tldr]
> Slicing from the end, why strings never change, and converting between bases. The traps that come with these live in [[coercion-gotchas]].

---

## Negative slice indices

```js
const greeting = 'Hello, World!';

greeting.slice(-6, -1);  // 'World'
```

A negative index counts back from the end. `-6` is the sixth character from the end, `-1` is the last one, and the end index is not included, so the exclamation mark is left out.

---

## Strings never change

```js
const str = 'Hello';
str.toUpperCase();
console.log(str);   // 'Hello', unchanged
```

Every string method returns a new string and leaves the original alone. If you do not keep the return value, nothing happened. This catches people because array methods like `sort` and `push` do the opposite.

Reassigning a `const` is a different error entirely:

```js
const name = 'John';
name = 'Jane';   // TypeError: Assignment to constant variable
```

---

## Template literals

```js
const a = 10;
const b = 20;
console.log(`The sum of ${a} and ${b} is ${a + b}`);
// The sum of 10 and 20 is 30
```

Anything inside `${}` is an expression, so it runs. Backticks also allow real line breaks inside the string.

---

## Converting numbers

```js
Number('10') === 10;   // true, strict conversion
parseInt('11', 2);     // 3, reading '11' as binary
(10).toString(2);      // '1010', writing 10 in binary
2 ** 3;                // 8, exponent operator
```

The second argument to `parseInt` is the base you are reading **from**. The argument to `toString` is the base you are writing **to**. Opposite directions, easy to mix up.

> [!tip] Always pass the base to parseInt
> Leaving it out lets the string decide, so a leading zero or an `0x` prefix changes the answer. `parseInt(value, 10)` every time, unless you mean otherwise. Passing it by accident is its own bug, see the `map(parseInt)` case in [[coercion-gotchas]].

---

## Big numbers lose precision, they do not overflow

The interview question is usually asked the other way round: in binary search, `mid = (low + high) / 2` breaks when `low` and `high` are near the maximum integer, so use `mid = low + (high - low) / 2` instead.

That fix is for languages with fixed width integers, like C++ or a Java `int`, where the addition wraps around into a negative number.

JavaScript has no integer type. Every number is a float64, so nothing wraps. What you get instead is silent precision loss above `Number.MAX_SAFE_INTEGER`, which is 2 to the power 53 minus 1:

```js
Number.MAX_SAFE_INTEGER;        // 9007199254740991
9007199254740993 === 9007199254740992;  // true, both round to the same float
```

Use `BigInt` when you genuinely need exact integers that large. And in JavaScript a binary search still needs `Math.floor((low + high) / 2)`, because dividing two integers gives you a fraction.

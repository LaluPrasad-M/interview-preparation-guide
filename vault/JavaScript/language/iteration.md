# Loops and Iteration

> [!tldr]
> Three loops that look alike but are not. `for...of` gives you values, `for...in` gives you keys, and objects work with only one.

---

## The three loops

```js
const my_array = ['apple', 'banana', 'cherry'];

for (let i = 0; i < my_array.length; i++) console.log(my_array[i]);  // apple, banana, cherry
for (const value of my_array) console.log(value);                    // apple, banana, cherry
for (const index in my_array) console.log(index, my_array[index]);   // 0 apple, 1 banana, 2 cherry
```

| Loop | Gives you | Works on |
| --- | --- | --- |
| `for` | an index you manage yourself | anything with a length |
| `for...of` | the value | iterables: arrays, strings, `Map`, `Set` |
| `for...in` | the key, as a string | any object, including inherited keys |

`for...in` hands you `'0'` and `'1'` as strings, not numbers.

---

## Objects are not iterable

```js
const my_map = { a: 'apple', b: 'banana', c: 'cherry' };

for (const value of my_map) console.log(value);
// TypeError: my_map is not iterable
```

A plain object has no iterator, so `for...of` throws. Two ways to fix it:

```js
for (const [key, value] of Object.entries(my_map)) console.log(key, value);

for (const key in my_map) console.log(key, my_map[key]);
```

**`Object.entries` is the one to reach for.** You get the key and the value together, and it ignores inherited properties.

---

## Switch cases share one scope

```js
let number = 1;
let numberType;          // has to live outside the switch

switch (number) {
  case 1:
    numberType = 'Odd';
    break;
  case 2:
    numberType = 'Even';
    break;
}
```

Declaring `let numberType` inside two different cases is an error. All cases share a single block. Wrap each case in braces:

```js
switch (number) {
  case 1: {
    let numberType = 'Odd';   // scoped to this case only
    console.log(numberType);
    break;
  }
  case 2: {
    let numberType = 'Even';
    console.log(numberType);
    break;
  }
}
```

Each case now gets its own scope.

---

## return does not escape a callback

```js
let a = 13;
const fn1 = function () {
  const lst = [0,1,2,3,4,5,6,7,8,9];
  lst.forEach(function (eachNum) {
    if (eachNum === 5) return 100;   // returns from THIS callback only
    else a = eachNum;
  });
  return 2000;
};
console.log(fn1(), a);   // 2000, 9

let b = 13;
const fn2 = function () {
  for (let i = 0; i < 10; i++) {
    if (i === 5) return 100;         // returns from fn2, loop stops
    else b = i;
  }
  return 4000;
};
console.log(fn2(), b);   // 100, 4
```

> [!warning] This is the difference between a loop and a callback
> `return` inside `forEach` ends that one callback and the iteration carries on. So `a` reaches 9 and the outer function still returns 2000. `return` inside a `for` loop exits the whole function. So `b` stops at 4. If you need to break out early, use a `for` loop, or `some`, or `find`.

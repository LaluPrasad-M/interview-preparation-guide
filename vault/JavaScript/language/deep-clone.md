# Deep Clone

> [!tldr]
> A shallow copy copies references inside an object, so changing the copy changes the original. A deep copy makes a new tree, independent all the way down.

---

## Why it matters

```js
const person1 = { name: 'Alice', country: { name: 'India', pincode: 123456 } };
const person2 = { ...person1 };

person2.country.pincode = 123123;
console.log(person1.country.pincode); // 123123, the original changed too
```

The spread operator copied `country` at the top level, but `country` is a reference. Both objects now point at the same inner object.

---

## structuredClone

The built-in answer, and the one to reach for.

```js
const person2 = structuredClone(person1);

person2.country.pincode = 123123;
console.log(person1.country); // { name: 'India', pincode: 123456 }
console.log(person2.country); // { name: 'India', pincode: 123123 }
```

Handles nested objects, arrays, `Map`, `Set` and `Date`.

---

## JSON stringify and parse

```js
const person2 = JSON.parse(JSON.stringify(person1));
```

It works. Everyone knows this trick.

> [!warning] What JSON silently throws away
> Functions, `undefined` and symbols vanish. A `Date` becomes a string. `NaN` and `Infinity` become `null`. Circular references throw.

---

## Writing it yourself

A common interview task, and worth knowing.

```js
function getReplicateObject(oldObj) {
  if (oldObj && typeof oldObj === 'object') {
    const newObj = Array.isArray(oldObj) ? [] : {};
    for (const [index, value] of Object.entries(oldObj)) {
      newObj[index] = getReplicateObject(value);
    }
    return newObj;
  }
  return oldObj;
}
```

The `Array.isArray` check keeps arrays as arrays instead of turning them into objects with numeric keys. The recursive call makes it deep. The `typeof` guard is the base case that stops recursion.

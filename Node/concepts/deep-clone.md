# Deep Clone

> [!tldr]
> Copying an object shallowly copies the references inside it, so changing the copy changes the original. Three ways to get a real, independent copy.

---

## Why it matters

```js
const person1 = { name: 'Alice', country: { name: 'India', pincode: 123456 } };
const person2 = { ...person1 };

person2.country.pincode = 123123;
console.log(person1.country.pincode); // 123123, the original changed too
```

The spread copied `country`, but `country` was a reference, so both objects point at the same inner object.

---

## structuredClone

The built in answer, and the one to reach for.

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

Works, and it is the trick everyone knows.

> [!warning] What JSON silently throws away
> Functions, `undefined` values and symbols vanish. A `Date` comes back as a string. `NaN` and `Infinity` become `null`. Circular references throw.

---

## Writing it yourself

Worth knowing because it is a common interview task, and it is short.

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

Two things carry the whole function. The `Array.isArray` check keeps arrays as arrays instead of turning them into objects with numeric keys. The recursive call is what makes it deep, and the `typeof` guard is the base case that stops it.

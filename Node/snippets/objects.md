# Object Snippets

> [!tldr]
> Merging, listing and iterating objects. See [[deep-clone]] for copying and [[object-locking]] for freezing.

---

## Merging

```js
const obj = { a: 1 };
const newObj = Object.assign(obj, { b: 2 }, { c: 3 });

console.log(newObj);          // { a: 1, b: 2, c: 3 }
console.log(obj === newObj);  // true
```

> [!warning] Object.assign mutates its first argument
> `obj` was changed, and `newObj` is the same object, not a copy. To merge without touching the original, pass a fresh target: `Object.assign({}, obj, { b: 2 })`, or use spread: `{ ...obj, b: 2 }`.

---

## Listing what is inside

```js
const obj = { a: 1, b: 2 };

Object.keys(obj);    // ['a', 'b']
Object.values(obj);  // [1, 2]
Object.entries(obj); // [['a', 1], ['b', 2]]
```

Entries is the useful one, because it destructures straight into a loop:

```js
const options = { a: 'hello', b: 'Bye' };

for (const [key, value] of Object.entries(options)) {
  console.log(`${key} : ${value}`);
}
```

All three ignore inherited properties and only report the object's own keys.

---

## Own property or inherited

```js
const obj = { name: 'John', age: 30 };
const obj2 = Object.create(obj);

obj2.name;                    // 'John', read through the prototype
obj2.hasOwnProperty('name');  // false
obj.hasOwnProperty('name');   // true
```

`Object.create(obj)` makes a new object whose prototype is `obj`. Reading works, but the property is not its own. See [[prototypes-and-classes]].

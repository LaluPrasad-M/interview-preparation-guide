# Object Locking

> [!tldr]
> `freeze`, `seal` and `preventExtensions`, three levels of locking an object from strictest to loosest. All three stop you adding new properties. They differ on deleting and changing what is already there.

---

## The comparison

| Can you | `Object.freeze()` | `Object.seal()` | `Object.preventExtensions()` |
| --- | --- | --- | --- |
| Add a property | no | no | no |
| Delete a property | no | no | yes |
| Change an existing value | no | yes | yes |
| Reconfigure a property | no | no | yes |
| Use it for | a value that must never change | fixed shape, changeable contents | stopping growth only |

The prototype chain is untouched by all three.

---

## Seeing the difference

```js
const frozen = { name: 'lalu', age: 23 };
Object.freeze(frozen);
frozen.name = 'laluPrasad';  // ignored
frozen.gender = 'Male';      // ignored
delete frozen.age;           // ignored

const sealed = { name: 'lalu', age: 23 };
Object.seal(sealed);
sealed.name = 'laluPrasad';  // works
sealed.gender = 'Male';      // ignored
delete sealed.age;           // ignored

const closed = { name: 'lalu', age: 23 };
Object.preventExtensions(closed);
closed.name = 'laluPrasad';  // works
closed.gender = 'Male';      // ignored
delete closed.age;           // works
```

---

## Checking the state

```js
console.log('freeze frozen ', frozen);
console.log('isFrozen frozen', Object.isFrozen(frozen));         // true
console.log('isSealed frozen', Object.isSealed(frozen));         // true
console.log('isExtensible frozen', Object.isExtensible(frozen)); // false

console.log('seal sealed ', sealed);
console.log('isFrozen sealed', Object.isFrozen(sealed));         // false
console.log('isSealed sealed', Object.isSealed(sealed));         // true
console.log('isExtensible sealed', Object.isExtensible(sealed)); // false

console.log('preventExtensions closed ', closed);
console.log('isFrozen closed', Object.isFrozen(closed));         // false
console.log('isSealed closed', Object.isSealed(closed));         // false
console.log('isExtensible closed', Object.isExtensible(closed)); // false
```

Same results as a table, for scanning:

| | `isFrozen` | `isSealed` | `isExtensible` |
| --- | --- | --- | --- |
| frozen | true | true | false |
| sealed | false | true | false |
| preventExtensions | false | false | false |

Two things fall out of it. Freezing implies sealing, so `isSealed` is true for a frozen object. And `isExtensible` is false for all three, because all three block new properties, which makes it the least informative of the three checks.

> [!warning] Freeze is only one level deep
> `Object.freeze(obj)` protects the top layer. A nested object inside it is still fully editable. Deep freezing means walking the object yourself and freezing every level.

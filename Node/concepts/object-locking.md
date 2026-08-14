# freeze vs seal vs preventExtensions

> [!tldr]
> Three levels of locking an object, from strictest to loosest. All three stop you adding new properties. They differ on deleting and changing what is already there.

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

Checking the state:

```js
Object.isFrozen(frozen);      // true
Object.isSealed(frozen);      // true, freeze implies seal
Object.isExtensible(frozen);  // false

Object.isFrozen(sealed);      // false
Object.isSealed(sealed);      // true
```

> [!warning] Freeze is only one level deep
> `Object.freeze(obj)` protects the top layer. A nested object inside it is still fully editable. Deep freezing means walking the object yourself and freezing every level.

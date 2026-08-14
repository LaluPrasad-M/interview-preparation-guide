# TypeScript Types

> [!tldr]
> Types can get more specific (narrowing) or more general (widening). Most TypeScript questions are really about which one is happening and why.

---

## Narrowing and widening

Think of it as a ladder: `any` at the top, `string` in the middle, the exact value `"Hello"` at the bottom.

**Narrowing** moves down. TypeScript works out that inside the `if`, the value can only be a string.

```ts
let value: any = 'Hello';

if (typeof value === 'string') {
  console.log(value.toUpperCase()); // safe, TypeScript knows it is a string here
}
```

**Widening** moves up, and throws away what you knew.

```ts
let value: string = 'Hello';
let anyValue: any = value;

anyValue = 42;  // allowed now, because any accepts anything
```

---

## let and const infer different types

```ts
let name_1 = 'Alice';     // inferred as string
const name_2 = 'Bob';     // inferred as "Bob", the literal
```

The reason is simple once you see it. `name_1` can be reassigned, so the type has to cover every string. `name_2` cannot, so the type can be exactly that one value.

---

## as const

Makes every property readonly, and narrows each one to its literal value. Works on objects and arrays.

```ts
const person_1 = { name: 'Jack', age: 32 };
// type is { name: string; age: number }

const person_2 = { name: 'Jack', age: 32 } as const;
// type is { readonly name: 'Jack'; readonly age: 32 }
```

`as const` and `<const>` are the same thing written two ways.

| | Locks the values | Narrows to literals |
| --- | --- | --- |
| `as const` | yes, at compile time | yes |
| `Object.freeze()` | yes, at runtime | no |
| `Readonly<T>` | yes, at compile time | no |

```ts
const person: Readonly<{ name: string; age: number }> = { name: 'Jack', age: 32 };
person.name = 'John'; // Error: cannot assign to a read-only property
```

There is a `Readonly` version of the collections too: `ReadonlyArray`, `ReadonlyMap`, `ReadonlySet`.

---

## Union and intersection

```ts
type Name = { name: string };
type Age = { age: number };

type Either = Name | Age;        // one, the other, or both
type Both = Name & Age;          // must have both
```

`|` is or, `&` is and. The catch is that `Name | Age` also accepts an object with both fields, which is often not what you meant.

```ts
const surprising: Either = { name: 'John', age: 30 }; // allowed
```

If you want to say "one, the other, or both, and I mean it", spell it out so the intent is visible to the next reader:

```ts
type EitherOrBoth = Name | Age | (Name & Age);
```

---

## Literal and template literal types

A type can be one exact string, or a pattern built from other types.

```ts
let exact: 'stringValue';
exact = 'stringValue';   // fine
exact = 'string';        // Error

type Size = 'small' | 'medium' | 'large';
type Color = 'primary' | 'secondary';
type Style = `${Size}-${Color}`;

const ok: Style = 'small-primary';       // fine
const typo: Style = 'medum-secondary';   // Error, caught at compile time
```

> [!tip] This is where TypeScript earns its keep
> Every valid combination is generated for you, and a typo in a class name or an event name becomes a compile error instead of a silent bug.

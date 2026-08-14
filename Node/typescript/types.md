# TypeScript Types

> [!tldr]
> Types can get more specific (narrowing) or more general (widening). Most TypeScript questions are really about which one is happening and why.

Run a TypeScript file with:

```bash
npx ts-node <file-path>
```

---

## Type aliases

A name for a type. It can be as broad or as narrow as you like.

```ts
type CollectiveType = number;      // every number
type LiteralType = 1337;           // only this one value
```

An alias creates no code. It disappears at compile time and exists purely so you can name a shape and reuse it.

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

const person_2 = {
  name: 'Jack',
  age: 32,
  address: {
    city: 'New York',
    country: 'USA',
  },
} as const;
// type is {
//   readonly name: 'Jack';
//   readonly age: 32;
//   readonly address: { readonly city: 'New York'; readonly country: 'USA' };
// }
```

The nested `address` is the part worth noticing. `as const` reaches all the way down, which is the difference from `Object.freeze`, and the reason the two are not interchangeable.

`as const` and `<const>` are the same thing written two ways.

| | Locks the values | Narrows to literals |
| --- | --- | --- |
| `as const` | yes, at compile time, all the way down | yes |
| `Object.freeze()` | yes, at runtime, top level only | no |
| `Readonly<T>` | yes, at compile time, top level only | no |

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

`|` is or, `&` is and. The catch is that `Name | Age` also accepts an object with both fields, which is often not what you meant. If you mean "one, the other, or both", spell it out so the intent is visible to the next reader:

```ts
type EitherNameOrAgeOrBothBad = Name | Age;
type BothNameAndAge = Name & Age;
type EitherNameOrAgeOrBothGood = Name | Age | BothNameAndAge;
```

The full set of assignments, which is the fastest way to see what each type really permits:

```ts
const my_name: Name = { name: 'John' };
const my_age: Age = { age: 30 };

const bad_1: EitherNameOrAgeOrBothBad = { name: 'John' };            // fine
const bad_2: EitherNameOrAgeOrBothBad = { age: 30 };                 // fine
const bad_3: EitherNameOrAgeOrBothBad = { name: 'John', age: 30 };   // allowed, but not what the name says

const both: BothNameAndAge = { name: 'John', age: 30 };              // required to have both

const good_1: EitherNameOrAgeOrBothGood = { name: 'John' };          // fine
const good_2: EitherNameOrAgeOrBothGood = { age: 30 };               // fine
const good_3: EitherNameOrAgeOrBothGood = { name: 'John', age: 30 }; // fine, and clearly intended
```

`bad_3` is the whole reason for the longer version. Both types accept the same three values, but only one of them says so out loud.

---

## Literal and template literal types

A type can be one exact string, or a pattern built from other types.

```ts
let str: string;
str = 'can be assigned any string value';

let exact: 'stringValue';
exact = 'stringValue';   // fine
exact = 'string';        // Error: not assignable to type '"stringValue"'
```

A template literal type mixes a fixed part with a flexible one:

```ts
let stringLiteral: `Example ${string}`;
stringLiteral = 'Example stringValue';        // fine
stringLiteral = 'Example anything at all';    // fine, the tail is any string
stringLiteral = 'Not starting with Example';  // Error
```

Or builds every combination of two unions:

```ts
type Size = 'small' | 'medium' | 'large';
type Color = 'primary' | 'secondary';
type Style = `${Size}-${Color}`;

const ok: Style = 'small-primary';       // fine
const typo: Style = 'medum-secondary';   // Error, caught at compile time
```

That last one is six valid strings generated from five words.

> [!tip] This is where TypeScript earns its keep
> Every valid combination is generated for you, and a typo in a class name or an event name becomes a compile error instead of a silent bug.

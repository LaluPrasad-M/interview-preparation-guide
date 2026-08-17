# TypeScript Types

> [!tldr]
> Types get more specific (narrowing) or more general (widening). Most TypeScript questions are really about which one is happening and why.

Run a TypeScript file:

```bash
npx ts-node <file-path>
```

---

## Type aliases

A name for a type. Broad or narrow.

```ts
type CollectiveType = number;      // every number
type LiteralType = 1337;           // only this one value
```

An alias creates no code. It disappears at compile time. It exists so you can name a shape and reuse it.

---

## Narrowing and widening

Think of it as a ladder: `any` at the top, `string` in the middle, the exact value `"Hello"` at the bottom.

**Narrowing** moves down. TypeScript works out that inside the `if`, the value can only be a string.

```ts
let value: any = 'Hello';

if (typeof value === 'string') {
  console.log(value.toUpperCase()); // safe here
}
```

**Widening** moves up. You lose what you knew.

```ts
let value: string = 'Hello';
let anyValue: any = value;

anyValue = 42;  // allowed now
```

---

## let and const infer different types

```ts
let name_1 = 'Alice';     // inferred as string
const name_2 = 'Bob';     // inferred as "Bob", the literal
```

`name_1` can be reassigned, so the type covers every string. `name_2` cannot, so the type is exactly that one value.

---

## as const

Makes every property readonly and narrows each to its literal value. Works on objects and arrays.

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

`as const` reaches all the way down. That is the difference from `Object.freeze`. They are not interchangeable.

`as const` and `<const>` are the same thing written two ways.

| | Locks the values | Narrows to literals |
| --- | --- | --- |
| `as const` | yes, compile time, all the way down | yes |
| `Object.freeze()` | yes, runtime, top level only | no |
| `Readonly<T>` | yes, compile time, top level only | no |

```ts
const person: Readonly<{ name: string; age: number }> = { name: 'Jack', age: 32 };
person.name = 'John'; // Error: cannot assign to readonly
```

Collections have `Readonly` versions too: `ReadonlyArray`, `ReadonlyMap`, `ReadonlySet`.

---

## Union and intersection

```ts
type Name = { name: string };
type Age = { age: number };

type Either = Name | Age;
type Both = Name & Age;
```

`|` is or, `&` is and. The catch: `Name | Age` accepts an object with both fields. That is often not what you mean. Spell it out:

```ts
type EitherNameOrAgeOrBothBad = Name | Age;
type BothNameAndAge = Name & Age;
type EitherNameOrAgeOrBothGood = Name | Age | BothNameAndAge;
```

The full set of assignments shows what each type accepts:

```ts
const my_name: Name = { name: 'John' };
const my_age: Age = { age: 30 };

const bad_1: EitherNameOrAgeOrBothBad = { name: 'John' };
const bad_2: EitherNameOrAgeOrBothBad = { age: 30 };
const bad_3: EitherNameOrAgeOrBothBad = { name: 'John', age: 30 };

const both: BothNameAndAge = { name: 'John', age: 30 };

const good_1: EitherNameOrAgeOrBothGood = { name: 'John' };
const good_2: EitherNameOrAgeOrBothGood = { age: 30 };
const good_3: EitherNameOrAgeOrBothGood = { name: 'John', age: 30 };
```

`bad_3` is the reason for the longer version. Both types accept the same three values. Only one says so out loud.

---

## Literal and template literal types

A type can be one exact string, or a pattern built from other types.

```ts
let str: string;
str = 'any string';

let exact: 'stringValue';
exact = 'stringValue';   // fine
exact = 'string';        // Error
```

A template literal mixes a fixed part with a flexible one:

```ts
let stringLiteral: `Example ${string}`;
stringLiteral = 'Example anything';        // fine
stringLiteral = 'Not starting with Example';  // Error
```

Build every combination of two unions:

```ts
type Size = 'small' | 'medium' | 'large';
type Color = 'primary' | 'secondary';
type Style = `${Size}-${Color}`;

const ok: Style = 'small-primary';       // fine
const typo: Style = 'medum-secondary';   // Error
```

Six valid strings generated from five words.

> [!tip] This is where TypeScript earns its keep
> Every valid combination is generated for you. A typo in a class name or event name becomes a compile error instead of a silent bug.

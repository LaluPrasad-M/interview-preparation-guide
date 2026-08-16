# TypeScript Compiler Internals

> [!tldr]
> TypeScript does not exist at runtime. The compiler checks your code, then erases every type, interface and generic before emitting plain JavaScript.

---

## Type erasure

`tsc` does one thing: it checks your code for logical errors, then completely erases all types, interfaces, generics and type aliases before emitting standard JavaScript.

> [!warning] The `instanceof` trap
> Because interfaces are erased at runtime, you cannot use them in runtime checks.
> ```ts
> interface User { name: string; }
> const obj = { name: "Rahul" };
>
> // Error: 'User' only refers to a type, but is being used as a value here.
> if (obj instanceof User) { }
> ```
> The fix is a custom type guard, or the `in` operator: `if ("name" in obj)`.

---

## The dual meaning of `extends`

The keyword does two completely different things depending on context.

**OOP context.** Inheritance, class A inherits from class B.

**Type context.** Constraint and assignability, is type A assignable to type B? `T extends string` means T must be a string or a literal subset of a string.

---

## Structural typing

Unlike Java or C# which use nominal typing, TypeScript uses structural typing. If it walks like a duck and quacks like a duck, TypeScript considers it a duck.

The compiler only cares about the shape of the object, not its explicit name or ancestry.

```ts
interface Vector2D { x: number; y: number; }
interface Point { x: number; y: number; }

class Position {
    constructor(public x: number, public y: number) {}
}

// Perfectly valid. TypeScript does not care about names,
// only that the structure (x, y) matches.
const v: Vector2D = new Position(10, 20);
const p: Point = v;
```

**The insight.** This makes mocking in unit tests incredibly easy. You do not need to instantiate complex classes, you just pass a raw object matching the structural shape.

---

## The type hierarchy

### `any` against `unknown`, the top types

**`any`** completely disables the compiler. It is a virus that destroys type safety. Avoid at all costs.

**`unknown`** is the safe alternative, meaning "I do not know what this is yet". You cannot perform operations on it until you explicitly narrow the type.

```ts
let data: unknown = fetchApi();
data.name; // Error: object is of type 'unknown'

// You must narrow it first:
if (typeof data === "object" && data !== null && "name" in data) {
    console.log(data.name); // now safe
}
```

### `never`, the bottom type

`never` represents a state that should never mathematically happen. Functions that throw or loop forever return `never`.

It is used heavily for exhaustive checking in `switch` statements.

```ts
type Shape = "Circle" | "Square";

function getArea(shape: Shape) {
    switch (shape) {
        case "Circle": return Math.PI;
        case "Square": return 4;
        default:
            // If another dev adds "Triangle" to Shape but forgets to update
            // this switch, TS throws a compile time error right here.
            const _exhaustiveCheck: never = shape;
            return _exhaustiveCheck;
    }
}
```

### User defined type guards

Functions that explicitly tell the compiler how to narrow a type.

```ts
interface Fish { swim(): void; }
interface Bird { fly(): void; }

// The return type 'pet is Fish' tells the compiler that if this returns true,
// the variable passed in is guaranteed to be a Fish.
function isFish(pet: Fish | Bird): pet is Fish {
    return (pet as Fish).swim !== undefined;
}
```

---

## Conditional types and `infer`

### Conditional types

Works exactly like a ternary, but for types. `T extends U ? X : Y` means if T is assignable to U return X, else return Y.

```ts
type StringOrNumberArray<T> = T extends string ? string[] : number[];

type T1 = StringOrNumberArray<string>;  // string[]
type T2 = StringOrNumberArray<boolean>; // number[]
```

### The `infer` keyword

`infer` acts as a variable declaration inside a conditional type. It says: figure out what this type is, store it in a temporary variable, and let me use it.

```ts
// If T is a Promise, infer its internal resolve type as R and return R.
type UnpackPromise<T> = T extends Promise<infer R> ? R : T;

type Result = UnpackPromise<Promise<User>>; // User
type Result2 = UnpackPromise<string>;       // string
```

---

## Mapped types, building utilities from scratch

In senior interviews you might be asked to implement `Partial`, `Pick` or `Omit` from scratch to prove you understand mapped types.

**`keyof T`** extracts all keys of an interface as a string literal union, for example `"name" | "age"`.

**`T[K]`** looks up the specific type of a key, so `User["name"]` is `string`.

### Rebuilding `Pick`

```ts
// 1. K must be a valid key of T.
// 2. Iterate over every property P in K.
// 3. Assign it the original type it had in T.
type MyPick<T, K extends keyof T> = {
    [P in K]: T[P];
};

interface User { id: number; name: string; email: string; }
type PublicUser = MyPick<User, "id" | "name">;
// Resolves to: { id: number; name: string; }
```

### Rebuilding `Omit`

```ts
type MyOmit<T, K extends keyof any> = MyPick<T, Exclude<keyof T, K>>;
```

---

## Gotchas

### The `enum` trap

Unlike interfaces, `enum` is one of the rare TypeScript features that actually generates real JavaScript. It creates an IIFE and a two way mapping object, which bloats bundle size and behaves oddly with number assignments.

The modern alternative is `as const`:

```ts
const Status = {
    PENDING: "PENDING",
    SUCCESS: "SUCCESS"
} as const;

// Extracts the union type: "PENDING" | "SUCCESS"
type StatusType = typeof Status[keyof typeof Status];
```

### Declaration merging, interface against type

`type` aliases are locked. Once defined they cannot be changed.

`interface` declarations remain open. Declaring the same interface twice makes TypeScript merge them into one.

```ts
interface Window { myCustomAPI: boolean; }
interface Window { init(): void; }

// TS merges them, so the global Window now has both properties.
// This is how you augment third party libraries, for example adding
// a user property to the Express Request type.
```

### Covariance and contravariance

**Covariance, return types.** You can return a more specific type than requested. If a function demands you return a `Vehicle`, returning a `Car` is safe.

**Contravariance, parameters.** Function parameters are contravariant. If a function asks for a callback taking a `Dog` and you provide a callback accepting an `Animal`, that is safe, because a dog is an animal. If you provide a callback requiring a `Greyhound`, that is unsafe, because the system might pass a poodle, which is a dog but not a greyhound.

TypeScript operates with `--strictFunctionTypes` to enforce this safely.

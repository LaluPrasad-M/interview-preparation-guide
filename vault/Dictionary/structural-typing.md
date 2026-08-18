# Structural Typing

> [!tldr]
> TypeScript decides whether two types match by comparing their shape, not their name. If an object has the right properties, it fits, whether or not anyone declared that it should.

```ts
interface Point { x: number; y: number }

class Coordinate {
  constructor(public x: number, public y: number) {}   // never mentions Point
}

const p: Point = new Coordinate(1, 2);                 // fine
```

Java or C# would reject that, because they use nominal typing, where a type only matches if it explicitly declares the relationship with `implements` or `extends`.

| | Structural, TypeScript | Nominal, Java and C# |
| --- | --- | --- |
| Matching rule | same shape is enough | declared identity is required |
| Fits an interface | any object with the right properties | only classes that say `implements` |
| Suits | describing data you did not define, like an API response | enforcing intent across a large class hierarchy |
| Risk | two unrelated things with the same shape are interchangeable | more ceremony to reuse anything |

This is why TypeScript feels light on JavaScript that already exists. You write the interface after the fact and it applies to the objects you already have, with nothing to change.

> [!warning] Same shape means same type, even when you did not mean it
> `{ id: string }` for a user ID and `{ id: string }` for an order ID are one type as far as the compiler is concerned, so nothing stops you passing one where the other belongs. Branded types, adding a phantom marker field, are the usual escape hatch when that distinction matters.

**Shows up in:** [[compiler-internals]].

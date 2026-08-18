# Structural Typing

> [!tldr]
> TypeScript decides if a type matches by comparing its shape, not its declared name or ancestry: if it walks like a duck and quacks like a duck, it counts as a duck.

Java and C# use nominal typing instead, where a type only matches if it explicitly declares that identity. In TypeScript, any object with the right properties satisfies an interface, whether or not it was ever declared to implement it.

**Shows up in:** [[compiler-internals]].

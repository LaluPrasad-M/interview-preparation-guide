# Type Erasure

> [!tldr]
> `tsc` checks types, then strips every type, interface, generic and type alias completely before emitting plain JavaScript.

None of that annotation exists at runtime. This is why TypeScript's type safety is entirely a compile time guarantee: a value that violates a type can still enter the running program if it comes from an unchecked source like `JSON.parse` or an untyped library.

**Shows up in:** [[compiler-internals]].

# Immediately Invoked Function Expression (IIFE)

> [!tldr]
> A function that is defined and run in the same statement, `(function () { ... })()`, so it never leaks a name into the surrounding scope.

Before ES modules existed, this was how you built a module: wrap everything in an IIFE, keep the internals private, and return only the pieces you want to expose. It is also how a counter or a mutex holds private state without a `private` keyword, since a closure inside the IIFE remembers its variables after the call returns.

TypeScript's compiled `enum` still generates one under the hood, which is part of why it bloats bundle size compared to `as const`.

**Shows up in:** [[function-types]], [[closures]], [[compiler-internals]], [[puzzles-scheduling-async-await]].

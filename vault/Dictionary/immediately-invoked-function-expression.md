# Immediately Invoked Function Expression (IIFE)

> [!tldr]
> A function that is written and called in the same breath, `(function () { ... })()`, so its variables live and die inside it and nothing new appears in the surrounding scope.

The wrapping parentheses are what make it an expression rather than a declaration, and the trailing `()` runs it on the spot. You never get a name to call again, which is the point.

> [!example]- Before modules existed, this was the module
>
> ```js
> const counter = (function () {
>   let count = 0;                       // nobody outside can reach this
>   return {
>     increment: () => ++count,
>     value: () => count,
>   };
> })();
>
> counter.increment();   // 1
> counter.count;         // undefined, there is no way in
> ```
> The returned object keeps working after the function has finished, because the closure it was defined in still remembers `count`. That is private state without a `private` keyword, and it is how a counter, a cache or a mutex hid its internals before `import` and `export` arrived.

| Problem | Old answer | Today |
| --- | --- | --- |
| Keep helpers out of the global scope | wrap the file in an IIFE | it is a module, top level is already private |
| Expose only part of a file | return an object from the IIFE | `export` the parts you want |
| Hold private state | a closure inside an IIFE | still this, or a `#private` class field |

You still meet them in compiled output even if you no longer write them. TypeScript's `enum` compiles to an IIFE that builds a lookup object at runtime, which is part of why it adds bundle weight where a plain `as const` object would not.

**Shows up in:** [[function-types]], [[closures]], [[compiler-internals]], [[puzzles-scheduling-async-await]].

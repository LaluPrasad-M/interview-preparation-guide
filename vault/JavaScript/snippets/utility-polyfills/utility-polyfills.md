# Utility Function Polyfills

> [!tldr]
> Ten utilities interviewers ask you to write from scratch, each with the mistake that actually gets made.

> [!warning] The rule that spans all of them
> Any higher order function must forward `this` and the arguments with `fn.apply(this, args)`. Missing that is a red flag.

---

## The parts

| Note | Covers |
| --- | --- |
| [[polyfills-array-methods]] | map, filter, reduce, compact, and groupBy with callback contracts |
| [[polyfills-function-utils]] | once, memoize, debounce, slice, and splice with higher-order function patterns |

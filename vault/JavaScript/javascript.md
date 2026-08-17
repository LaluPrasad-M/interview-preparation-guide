# JavaScript

> [!tldr]
> Index for everything under `JavaScript/`. The language itself, the Node runtime built on it, snippets to reach for, and TypeScript on top.

---

## JavaScript

The language itself, independent of where it runs.

| Note | Covers |
| --- | --- |
| [[function-types]] | named, anonymous, arrow, IIFE, pure, curried, higher order, generators |
| [[prototypes-and-classes]] | constructor functions, ES6 classes, the prototype chain, hasOwnProperty |
| [[var-vs-let]] | scope, hoisting, the temporal dead zone, the setTimeout loop question |
| [[closures]] | why a function remembers variables that should be gone |
| [[this-binding]] | call, apply, and bind, and when you need each one |
| [[iteration]] | for against for...of against for...in, switch scoping, return inside a callback |
| [[deep-clone]] | structuredClone, the JSON trick and what it drops, writing it yourself |
| [[object-locking]] | freeze, seal, and preventExtensions |
| [[coercion-gotchas]] | the output puzzles: type juggling, sort, parseInt, falsy against nullish |
| [[engine-internals]] | execution context and hoisting, the five `this` binding rules, `prototype` against `__proto__`, stack and heap, the TDZ |

---

## Runtime

How Node executes your code, loads it, and stops two things happening at once.

| Note | Covers |
| --- | --- |
| [[event-loop]] | nextTick, promises, setTimeout and setImmediate, and the order questions built on them |
| [[promises]] | all, allSettled, race, any, how errors travel through await, the cooking chain example |
| [[modules]] | ES Modules against CommonJS, sync against async loading, the export footgun |
| [[worker-threads]] | moving CPU heavy work off the main thread. Written from scratch, your notebook stops at the heading |
| [[locks]] | mutex in one process, Redis lock across processes, table lock in the database |
| [[puzzles-scheduling]] | 13 what does this print questions on the event loop, in three parts: basics, async await |
| [[puzzles-promises]] | 15 combinator and error handling questions, in three parts: error handling, combinators |
| [[production-prompts]] | six interview prompts: limiter, rate limiter, job queue, singleflight, graceful shutdown |
| [[middleware-recursion]] | why a loop cannot sequence middleware, with the proof |

---

## Snippets

Language and utility code, the things you reach for while solving something.

| Note | Covers |
| --- | --- |
| [[arrays]] | what each method returns, creating arrays and grids, destructuring, slice against splice |
| [[objects]] | assign, keys and values and entries, own properties against inherited |
| [[strings-and-numbers]] | negative slice, string immutability, template literals, base conversion |
| [[timers-and-concurrency]] | sleep, cancellable timers, timeout wrapper, progress, concurrency pool, map and filter and reduce written out |
| [[console]] | grouping, styling, table, time, trace |
| [[utility-polyfills]] | map, filter, reduce, compact, groupBy, once, memoize, debounce, slice, splice |

---

### Server

Under `node/server/`. Whole servers you can run, rather than pieces you drop into something else.

| Note | Covers |
| --- | --- |
| [[http-server]] | a server with no framework, routing, POST bodies, middleware by hand |
| [[express-server]] | routes, params, query, full CRUD across five routes, in memory cache |
| [[express-internals]] | what Express is, streaming bodies, the consumed stream rule |
| [[req-res-reference]] | every event, method and property on both streams, plus end against close |

---

## TypeScript

| Note | Covers |
| --- | --- |
| [[types]] | narrowing and widening, as const, Readonly, unions, template literal types, running a file |
| [[enums]] | why number enums break over a network, and what to use instead |
| [[compiler-internals]] | type erasure, structural typing, `any` against `unknown` against `never`, `infer`, mapped types |
| [[private-static-and-locks]] | what each keyword controls, and why async code needs a mutex |

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[patterns-js-vs-ts]] | `Design/patterns/` | it compares design patterns across the two languages, not the languages themselves |
| [[js-vs-ts-compilation]] | `Design/object-design/` | it is about what OOP pillars compile down to, not JavaScript on its own |
| [[solid-js-vs-ts]] | `Design/object-design/` | SOLID is an OOP concept, this note just shows it in both languages |

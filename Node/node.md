# Node.js

> [!tldr]
> Index for everything under `Node/`. Concepts are the theory questions, snippets are code worth having ready, typescript is the type system on top.

---

## Concepts

| Note | Covers |
| --- | --- |
| [[event-loop]] | nextTick, promises, setTimeout and setImmediate, and the order questions built on them |
| [[promises]] | all, allSettled, race, any, how errors travel through await, the cooking chain example |
| [[function-types]] | named, anonymous, arrow, IIFE, pure, curried, higher order, generators |
| [[prototypes-and-classes]] | constructor functions, ES6 classes, the prototype chain, hasOwnProperty |
| [[var-vs-let]] | scope, hoisting, the temporary dead zone, the setTimeout loop question |
| [[closures]] | why a function remembers variables that should be gone |
| [[iteration]] | for against for...of against for...in, switch scoping, return inside a callback |
| [[this-binding]] | call, apply and bind, and when you need each |
| [[modules]] | ES Modules against CommonJS, and the export footgun |
| [[deep-clone]] | structuredClone, the JSON trick and what it drops, writing it yourself |
| [[object-locking]] | freeze, seal and preventExtensions |
| [[coercion-gotchas]] | the output puzzles: type juggling, sort, parseInt, falsy against nullish |
| [[locks]] | mutex in one process, Redis lock across processes, table lock in the database |
| [[worker-threads]] | moving CPU heavy work off the main thread. Written from scratch, your notebook stops at the heading |

---

## Snippets

| Note | Covers |
| --- | --- |
| [[http-server]] | a server with no framework, routing, POST bodies, middleware by hand |
| [[express-server]] | routes, params, query, a full CRUD API, in memory cache |
| [[timers-and-concurrency]] | sleep, cancellable timers, timeout wrapper, progress, concurrency pool, map and filter and reduce written out |
| [[arrays]] | what each method returns, creating arrays and grids, destructuring, slice against splice |
| [[objects]] | assign, keys and values and entries, own properties against inherited |
| [[strings-and-numbers]] | negative slice, string immutability, template literals, base conversion |
| [[console]] | grouping, styling, table, time, trace |

---

## TypeScript

| Note | Covers |
| --- | --- |
| [[types]] | narrowing and widening, as const, Readonly, unions, template literal types |
| [[enums]] | why number enums break over a network, and what to use instead |

---

## Run a TypeScript file

```bash
npx ts-node <file-path>
```

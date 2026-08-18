# Type Erasure

> [!tldr]
> The TypeScript compiler (`tsc`) checks your types, then deletes every one of them before emitting JavaScript. Types exist while you are compiling and nowhere else.

```ts
interface User { id: number; name: string }

function greet(user: User): string {
  return `hi ${user.name}`;
}
```

compiles to exactly this, with the interface gone entirely:

```js
function greet(user) {
  return `hi ${user.name}`;
}
```

Interfaces, type aliases, generics and annotations all vanish. Nothing about `User` survives into the running program, so there is nothing at runtime to check a value against.

| Erased completely | Emits real JavaScript |
| --- | --- |
| `interface`, `type` | `class` |
| generic parameters like `<T>` | `enum`, which becomes a lookup object |
| all type annotations | `namespace`, which becomes an object |

That is why type safety stops at the boundary. `JSON.parse` returns `any`, an untyped library can hand back whatever it likes, and a database driver can give you a string where your type says number. The compiler was satisfied and the program is wrong.

> [!warning] `as` is a promise, not a check
> `const user = JSON.parse(body) as User` compiles to `JSON.parse(body)`. You told the compiler to stop worrying and nothing was verified. Validating at the edge with Zod or a hand written guard is the only thing that actually inspects the value, because a runtime check has to be code, not a type.

**Shows up in:** [[compiler-internals]].

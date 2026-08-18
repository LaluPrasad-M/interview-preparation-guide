# Promises

> [!tldr]
> Four combinators, and one rule about errors: an `await` that rejects behaves exactly like a `throw`, so `try` and `catch` work normally.

Two helpers used throughout, the same pair as [[puzzles-promises]]. One resolves, one rejects, and they are named differently so no snippet is ambiguous about which it means:

```js
function fetchData(t = 1000, value = 'Data') {
  return new Promise(resolve => setTimeout(resolve, t, value));
}

function failData(t = 1000) {
  return new Promise((_, reject) => setTimeout(reject, t, new Error('Error occurred')));
}
```

---

## The parts

| Note | Covers |
| --- | --- |
| [[promise-combinators-and-errors]] | the four combinators, all vs allSettled, error propagation and try/catch/finally patterns |
| [[promise-advanced-patterns]] | the cooking example, implementing cancellable promises, and writing Promise from scratch |

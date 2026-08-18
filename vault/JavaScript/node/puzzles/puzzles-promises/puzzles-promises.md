# Promise Puzzles

> [!tldr]
> The combinator and error handling questions, answers folded. The rules are in [[promises]], the event loop ordering ones are in [[puzzles-scheduling]].

Assume these two helpers throughout:

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
| [[promise-combinators]] | Promise.all, allSettled, and race with different resolution and rejection patterns |
| [[promise-error-handling]] | how await rejection behaves like throw, try/catch/finally interactions, and error propagation |

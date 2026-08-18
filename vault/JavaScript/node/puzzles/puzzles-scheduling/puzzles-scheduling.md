# Scheduling Puzzles

> [!tldr]
> Every "what does this print" question about the event loop, with the answer folded away. Read the code, commit to an answer, then unfold. The rules behind them are in [[event-loop]].

Where a puzzle below uses `fetchData` or `callback` without defining them, they are these. This `fetchData` takes no arguments, unlike the parameterised one in [[puzzles-promises]], because none of these puzzles need to vary the delay:

```js
function fetchData() {
  return new Promise(resolve => setTimeout(resolve, 1000, 'Data'));
}

function callback() {
  console.log('Callback');
}
```

---

## The parts

| Note | Covers |
| --- | --- |
| [[puzzles-scheduling-basics]] | timing fundamentals: zero delay, setImmediate vs setTimeout, and when the microtask queue drains |
| [[puzzles-scheduling-async-await]] | how await suspends, the queue interaction puzzle, and resolve vs return |

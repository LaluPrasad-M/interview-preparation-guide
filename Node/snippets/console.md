# Console Tricks

> [!tldr]
> `console.log` is not the only one. Grouping and styling make a noisy log readable.

---

## Grouping

Nested groups become collapsible sections, and everything inside one is indented.

```js
console.group('simple');
  console.group('warnings');
    console.warn('warning 1!');
    console.warn('warning 2!');
  console.groupEnd();
  console.error('error here');
  console.log('vivi vini vici');
console.groupEnd();

console.log('new section');
```

Every `console.group` needs its own `console.groupEnd`, and the label you pass to `groupEnd` is ignored, so the pairing is purely positional.

---

## Styling

```js
console.log('%c Hello from scratch.js', 'background: #222; color: #f00; font-size: 20px');
```

`%c` says "style everything after this using the next argument". Browser devtools honour it. A plain terminal does not, so it is a browser trick rather than a Node one.

---

## Worth knowing about

| Method | Does |
| --- | --- |
| `console.table(arr)` | prints an array of objects as a real table |
| `console.time` and `console.timeEnd` | measures how long something took, using the same label for both |
| `console.trace()` | prints the call stack from where it was called |
| `console.error` and `console.warn` | go to stderr, so they can be piped separately from normal output |

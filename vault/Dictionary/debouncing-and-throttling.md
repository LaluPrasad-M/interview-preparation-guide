# Debouncing and Throttling

> [!tldr]
> Both stop a function from running too often. Debouncing waits for the activity to stop and then runs once. Throttling runs straight away and then refuses to run again until a fixed gap has passed.

| | Debounce | Throttle |
| --- | --- | --- |
| Runs when | the events go quiet for `n` ms | at most once every `n` ms, while events keep coming |
| During a long burst | nothing runs at all | it runs steadily, at a capped rate |
| Good for | search boxes, autosave, resize handlers | scroll handlers, mousemove, sending live progress |
| Wrong choice looks like | a scroll handler that only fires once you stop scrolling | a search box firing one request per keystroke |

> [!example]- The same 10 keystrokes, one per 100 ms
>
> ```text
> keystrokes   x x x x x x x x x x            then a pause
> debounce 500ms                     -> 1 call, after the pause
> throttle 500ms   ->      ->        -> 3 calls, spread across the burst
> ```
> A search box wants the debounce: you only care what the user finished typing. A scroll position indicator wants the throttle: you need updates while the scrolling is still happening, just not 60 times a second.

```js
function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);              // the whole trick is here
    timer = setTimeout(() => fn(...args), delay);
  };
}

function throttle(fn, gap) {
  let last = 0;
  return (...args) => {
    const now = Date.now();
    if (now - last < gap) return;
    last = now;
    fn(...args);
  };
}
```

> [!warning] Forgetting `clearTimeout` is the classic bug
> Without that line every call schedules its own timer, so ten keystrokes fire ten calls half a second later. You have built a delay, not a debounce, and it is easy to miss because the behaviour looks almost right.

**Shows up in:** [[react-fundamentals]], [[polyfills-function-utils]], [[react-implementation-basics]], [[designing-the-four-layers]], [[webhook-ingestion]], [[geospatial-discovery]], [[idempotency]].

# Debouncing and Throttling

> [!tldr]
> Debouncing waits for activity to stop before running; throttling runs at most once per fixed interval no matter how often the event fires.

A search box debounces its API call, waiting 500ms after the user stops typing so it does not fire on every keystroke. A scroll handler throttles instead, running at most once every 200ms, because it needs steady updates while scrolling continues, not just a final one after it stops.

The common bug in a hand-rolled debounce is forgetting `clearTimeout` on each call, which turns it into a plain delay instead of a debounce.

**Shows up in:** [[react-fundamentals]], [[polyfills-function-utils]].

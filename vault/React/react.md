# React

> [!tldr]
> The mental model first, then the ten components you will actually be asked to write live.

---

## Notes

| Note | Covers |
| --- | --- |
| [[react-fundamentals]] | the virtual DOM and reconciliation, state and immutability, the hooks table, performance, ten theory questions |
| [[coding-implementations]] | counter, fetch, todo, debounced search, context, filter, form, custom hook, toggle, modal, in three parts: basics, patterns |

---

## What to study first

Four tiers, in the order they get asked.

| Tier | Topics |
| --- | --- |
| 1, non negotiable | JSX and rendering, function components, props against state, `useState`, `useEffect`, lifecycle the modern way, controlled against uncontrolled inputs, lifting state up, keys in lists, conditional rendering, events, forms |
| 2, expected at SDE2 | reconciliation and the virtual DOM, how rendering actually works, batching, `useRef`, `useMemo`, `useCallback`, `React.memo`, context, custom hooks, error boundaries, code splitting with `React.lazy` and `Suspense` |
| 3, real world | folder structure, state management with Redux or Zustand, routing, data fetching patterns, async state, debouncing and throttling, optimistic UI, form libraries |
| 4, differentiators | concurrent rendering, `useTransition`, `useDeferredValue`, Suspense for data, server side rendering against client side rendering, hydration, Next.js basics, micro frontends |

Tiers 1 and 2 are what [[react-fundamentals]] and [[coding-implementations]] cover.
Tiers 3 and 4 are worth being able to talk about even where there is no note yet.

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[designing-the-four-layers]] | `Design/system-design/` | the system design layer for the client, not React specifics |

# React Fundamentals

> [!tldr]
> A re-render is not a DOM mutation. React re-renders children by default to check whether their output changed, and only touches the real DOM if it did.

---

## Architecture and the rendering engine

**The DOM.** The browser reads your HTML and builds a tree in memory.
That tree is the DOM, and JavaScript can change it.

**The problem with it.** Changing the DOM directly is slow and hard to keep in sync as apps grow.

**Declarative vs imperative.** React is declarative: you describe what the UI should look like, and React updates the DOM to match.
Manual DOM manipulation with `document.getElementById` is imperative.

**JSX and React elements.** JSX looks like HTML but it is JavaScript.
It compiles down to `React.createElement()` calls.
Each call returns a React element, which is just an object describing one UI node: `{ type: "h1", props: { children: 0 } }`.

### The rendering process

1. The component function runs and returns JSX.
2. React converts that JSX into React elements, building a tree in memory called the virtual DOM.
3. When state changes, a new virtual DOM tree is created.
4. React compares the new tree against the old one.
5. React finds the differences and updates only those parts in the real DOM.

**Reconciliation** is the name for that comparison process. It is also called the diffing algorithm.

> [!warning] The crucial nuance
> A component re-render does not mean a DOM mutation. React re-renders child components by default to check whether their output changed. If there is no actual difference, the real DOM is not touched.

---

## State, props and immutability

**Components.** These are reusable pieces of UI.
They are JavaScript functions that return JSX.
They can receive props and manage state.

**Props.** They are read-only data passed down from parent to child.
Data only flows one way: parent to child.

**State.** It is data managed inside a component that changes over time.
Updating state triggers a re-render.
State updates are asynchronous.

**Immutability.** Never mutate state directly.
Never do `arr.push(4)`.
React checks reference equality.
If the reference does not change, React assumes nothing changed and skips the re-render.
Always pass a new reference: `setArr(prev => [...prev, 4])`.

**Functional updates.** Use them when the new state depends on the old.
For example, `setCount(prev => prev + 1)`.
Standard state variables are snapshots.
If you fire multiple updates fast, they might use stale data.
Functional updates guarantee you use the latest state.

**Lists and keys.** Siblings in a list must have unique keys, and those keys must be stable.
React uses keys to identify which element is which during reconciliation.
Using the array index as a key breaks when the list order changes, causing UI bugs.

---

## The essential hooks

| Hook | Purpose | Re-render? |
| --- | --- | --- |
| `useState` | adds state to a functional component | yes |
| `useEffect` | runs code after a render (API calls, timers) | no, but state updates inside do |
| `useRef` | persists a value without re-rendering, or accesses DOM nodes | no |
| `useMemo` | caches a computed value | no |
| `useCallback` | caches a function reference | no |
| `useContext` | shares data without prop drilling | yes, if the value changes |

---

## Performance and scaling

Scaling React means faster rendering, fewer unnecessary renders, smaller bundles, and less memory.

**Virtualisation.** This gives the most return.
For huge lists, say 10,000 rows, render only the visible ones using `react-window` or `react-virtualized`.
Only the roughly 20 visible rows exist in the real DOM.

**React.memo.** It caches component output, so parent re-renders do not force child re-renders when props did not change.

**useMemo vs useCallback.** `useMemo` caches a computed value and recalculates only when dependencies change.
`useCallback` caches a function reference.
If you create a new function on every render, child components see a different function object and re-render unnecessarily.

**Code splitting.** Fix large bundle sizes using `React.lazy` and `<Suspense>`.
Component code downloads only when needed, not up front.

**[[debouncing-and-throttling|Debouncing and throttling]].** Debouncing delays execution until activity stops: wait 500 ms after the user stops typing before calling the search API.
Throttling caps execution: handle a scroll event at most once every 200 ms.

**API caching.** Use TanStack Query or SWR to prevent repeated fetches.
They provide caching, retries, and deduplication.

**Context re-renders.** Every consumer of a context re-renders when its value changes, even the ones that only read a field that did not change.
Two fixes: split one big context into several small ones, and memoise the value you pass to the provider so a new object is not created on every parent render.

```jsx
const value = useMemo(() => ({ user, theme }), [user, theme]);
```

**Images.** A slow first paint is often images, not JavaScript.
Add `loading="lazy"` to anything below the fold, serve sized versions rather than one huge file, compress, and put a [[cdn|CDN]] in front.

**Fix them in this order.**

1. Measure with the React DevTools Profiler.
2. Find the renders that should not be happening.
3. Apply `React.memo`, `useMemo` and `useCallback` where the profiler pointed.
4. Virtualise long lists and lazy load routes.
5. Debounce typing, throttle scroll, cache API calls, split contexts.

Step 1 is the answer to the question.
Everything after it is guesswork if you skip it.

> [!warning] The optimisation caveat
> Do not use `useMemo` and `useCallback` everywhere.
> They have their own overhead.
> Only optimise when profiling shows a measurable benefit.

---

## The ten theory questions

**What happens under the hood when setState is called?**
React calls the component function again and new JSX is returned.
That JSX becomes a new virtual DOM tree.
React uses reconciliation to compare it with the old tree.
React identifies the exact differences.
Then React surgically updates only the changed nodes in the real DOM, without rebuilding it.

**Why is mutating state directly bad?**
React checks state changes using reference equality.
If you push to an array directly, the memory reference does not change.
React sees the same reference, assumes nothing changed, and skips the re-render.
The UI falls out of sync with the state.

**When should you use a functional update?**
You should use it when the new state depends on the old value.
Standard state variables are snapshots.
If you fire multiple updates fast, the later ones might use stale data.
Functional updates guarantee you calculate against the latest state.

**Why is the array index dangerous as a key?**
The key prop helps React identify which elements changed, were added, or removed.
Keys must be unique among siblings and stable across renders.
If you use the index as a key and the list order changes, React maps data to the wrong DOM elements, causing UI bugs.

**Exact difference between useMemo and useCallback?**
`useMemo` caches a computed value and re-runs the calculation only when dependencies change.
`useCallback` caches a function reference.
The difference matters when passing function props to children.
A new function on every render makes the child think its props changed and re-render unnecessarily.

**What is prop drilling and how do you solve it?**
Prop drilling is passing props down through multiple layers of components that do not need the data, just to reach a deeply nested child.
Solve it with the Context API or a global state manager.
They share state without manual passing.

**A page has 10,000 records and is slow. What do you do?**
Do not render all 10,000 rows at once.
Implement virtualisation so only the roughly 20 visible rows exist in the real DOM.
This gives the highest performance return.

**Explain the useEffect dependency array.**
No array: runs on every render, which is rarely desired.
Empty array: runs once on mount.
Array with variables: runs on mount and whenever any of those variables change.

**What is the cleanup function for?**
It runs when a component unmounts.
It is critical for cleaning up side effects and avoiding memory leaks.
Clear timers, close WebSockets, unsubscribe from events.

**Parent re-renders are causing performance issues. How do you fix it?**
By default React re-renders children to check if their output changed.
Wrap the child in `React.memo`.
It caches the output and prevents re-rendering when props are unchanged.

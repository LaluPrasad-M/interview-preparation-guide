# React Fundamentals

> [!tldr]
> A re-render is not a DOM mutation. React re-renders children by default to check whether their output changed, and only touches the real DOM if it did.

---

## Architecture and the rendering engine

**The DOM.** A tree like in memory representation of HTML created by the browser. The browser converts HTML into the DOM tree, which lives in memory and can be manipulated by JavaScript.

**The problem with it.** Direct DOM manipulation is expensive and hard to scale for complex applications.

**Declarative against imperative.** React is declarative: you describe the UI and React updates the DOM. Manual manipulation such as `document.getElementById` is imperative.

**JSX and React elements.** JSX looks like HTML but is JavaScript. It compiles down to `React.createElement()` calls, producing a React element, which is just an object describing the UI node, for example `{ type: "h1", props: { children: 0 } }`.

### The rendering process

1. The component function runs and returns JSX.
2. The JSX is converted into React elements, creating a virtual DOM tree.
3. When state changes, a new virtual DOM tree is created.
4. React compares the new tree against the old one.
5. It finds the exact differences and updates only those changed nodes in the real DOM.

**Reconciliation and the diffing algorithm** is the technical term for that comparison process.

> [!warning] The crucial nuance
> A component re-render does not mean a DOM mutation. React re-renders child components by default to check whether their output changed. If there is no actual difference, the real DOM is not touched.

---

## State, props and immutability

**Components.** Reusable pieces of UI, JavaScript functions returning JSX, which can receive props and manage state.

**Props.** Read only data passed downwards from parent to child. Data flows strictly parent to child.

**State.** Data managed internally that changes over time. Updating state triggers a re-render, and updates are asynchronous.

**Immutability.** Never mutate state directly, for example `arr.push(4)`. React checks reference equality, and if the reference does not change React skips the re-render. Always pass a new reference: `setArr(prev => [...prev, 4])`.

**Functional updates.** Use them when the new state depends on the old, for example `setCount(prev => prev + 1)`. Standard state variables act as snapshots, while functional updates guarantee you use the latest state.

**Lists and keys.** Siblings must have unique keys, which must be stable, so React can identify elements during reconciliation. Using the array index as a key is bad practice and causes UI bugs when the list order changes.

---

## The essential hooks

| Hook | Purpose | Triggers re-render? |
| --- | --- | --- |
| `useState` | adds state to functional components, managing local UI state | yes |
| `useEffect` | handles side effects after a render, such as API calls and timers | no, but internal state updates do |
| `useRef` | persists a value without impacting the UI, or accesses DOM nodes | no |
| `useMemo` | memoises an expensive computed value | no |
| `useCallback` | memoises a function reference to prevent unnecessary child re-renders | no |
| `useContext` | shares global data to avoid prop drilling | yes, if the context value changes |

---

## Performance and scaling

Scaling in React means faster rendering, less unnecessary rendering, smaller JS bundles, less memory usage, and faster initial page loads.

**Virtualisation, the highest return.** For massive lists, for example 10,000 records, use `react-window` or `react-virtualized` to render only the roughly 20 rows currently visible in the DOM.

**`React.memo`.** Memoises component output, preventing parent re-renders from trickling down to children when the child's props are unchanged.

**`useMemo` against `useCallback`.** `useMemo` caches a computed value so it only recomputes when dependencies change. `useCallback` caches a function reference. Creating new functions on every render makes child components see a different function and re-render unnecessarily.

**Code splitting.** Fixes large bundle sizes using `React.lazy` and `<Suspense>` to download component code only when needed.

**Debouncing and throttling.** Debouncing delays execution until activity stops, for example waiting 500 ms after the user stops typing before calling a search API. Throttling ensures execution happens at most once every X milliseconds, for example handling a scroll event every 200 ms.

**API caching.** Use TanStack Query or SWR to prevent repeated fetches, providing caching, retries and deduplication.

> [!warning] The optimisation caveat
> Do not use `useMemo` and `useCallback` everywhere, because of their own overhead. Only optimise when profiling shows a measurable benefit.

---

## The ten theory questions

**What happens under the hood when `setState` is called?** React calls the component function again and new JSX is returned. That JSX becomes a new virtual DOM tree. React uses reconciliation to compare it with the old tree, identifies the exact differences, and surgically updates only the changed nodes in the real DOM, without recreating the entire DOM.

**Why is mutating state directly bad?** React checks state changes using reference equality. If you push to an array directly, the memory reference does not change, React sees the same reference, assumes nothing changed, and skips the re-render, leaving the UI out of sync.

**When should you use a functional update?** When the new state depends on the old. Standard state variables act as a snapshot, so fast sequential updates might rely on stale data. Functional updates guarantee you calculate against the latest state.

**Why is the array index dangerous as a key?** The `key` prop helps React identify which elements changed, were added or removed during reconciliation. Keys must be unique among siblings and stable. If you use the index and the list order changes, React maps data incorrectly to DOM elements, causing UI bugs.

**Exact difference between `useMemo` and `useCallback`?** `useMemo` memoises a computed value, re-running the expensive calculation only when dependencies change. `useCallback` memoises a function reference, which matters when passing function props to children, because it prevents the child re-rendering just because a new function instance was created.

**What is prop drilling and how do you solve it?** Passing props down through multiple layers of components that do not need the data, simply to reach a deeply nested child. Solve it with the Context API or a global state manager, sharing state without manual passing.

**A page has 10,000 records and is slow. What do you do?** Do not render all 10,000 rows at once. Implement list virtualisation, so only the roughly 20 visible rows exist in the real DOM. That is the highest performance return.

**Explain the `useEffect` dependency array.** No array means it runs on every render, which is rarely desired. An empty array means it runs once on mount. An array with variables means it runs on mount and whenever those variables change.

**What is the cleanup function for?** It runs when a component unmounts. It is critical for cleaning up side effects to avoid memory leaks, such as clearing timers or closing open WebSockets.

**Parent re-renders are causing performance issues. How do you fix it?** By default React cannot assume a child's output is the same, so parent re-renders force child re-renders. Wrap the child in `React.memo`, which memoises the output and prevents re-rendering when props are unchanged.

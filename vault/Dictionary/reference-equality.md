# Reference Equality

> [!tldr]
> React decides whether something changed by asking "is this the same object in memory as before", not "does it look the same". Change the contents of an object and React sees no change at all.

Comparing contents would mean walking every nested field on every render, which would be slow. Comparing references is one pointer check, so React does that and pushes the work of creating new objects onto you.

> [!example]- The same array, mutated and replaced
> ```js
> // no re-render: same array object, React sees nothing to do
> const handleAddBroken = () => {
>   arr.push(4);
>   setArr(arr);
> };
>
> // re-renders: a brand new array, so a new reference
> const handleAdd = () => setArr((prev) => [...prev, 4]);
> ```
> The broken version does change the data. The screen just never updates, which is why it is such a confusing bug to hit the first time.

The same rule explains the hooks that look like pure ceremony.

| Value | Recreated every render | Consequence |
| --- | --- | --- |
| A function defined in the component | yes, new reference each time | a memoised child re-renders anyway, until `useCallback` |
| An object or array literal in props | yes | same problem, until `useMemo` |
| A dependency array entry | compared by reference | an object dependency makes `useEffect` run every render |

> [!tip] This is why state is treated as immutable
> Not because mutation is wicked, but because React's change detection is a reference check, and mutation is invisible to a reference check. Replace, do not edit in place.

**Shows up in:** [[react-fundamentals]].

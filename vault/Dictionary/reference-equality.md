# Reference Equality

> [!tldr]
> React decides whether a value changed by comparing whether it is the same object in memory, not whether its contents look the same.

Pushing to an array with `arr.push(4)` keeps the same reference, so React sees no change and skips the re-render, even though the array's contents did change. Replacing it with a new array, `setArr(prev => [...prev, 4])`, gives React a new reference to compare against.

The same check is why `useCallback` matters: a function recreated on every render is a new reference every time, so a child component receiving it as a prop re-renders even though the function's behavior did not change.

**Shows up in:** [[react-fundamentals]].

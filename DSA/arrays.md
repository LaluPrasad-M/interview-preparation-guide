---
tags: [revise]
owner: lalu
---

# Arrays

## Idea

Contiguous memory, O(1) indexing. Most array problems reduce to: can I avoid the
nested loop by carrying state as I move a pointer? The three ways to carry state
are [[two-pointer]], [[sliding-window]] and [[prefix-sum]].

## When to reach for it

- "Subarray" / "contiguous" → sliding window or prefix sum.
- Sorted input, or sorting is free → two pointers.
- "Range sum queries" → prefix sum, or a Fenwick tree if updates happen.
- "Find the duplicate / missing" with values bounded by `n` → index-as-hash, negate in place.

## Template

Max-sum window of size `k`:

```cpp
long long best = 0, cur = 0;
for (int i = 0; i < n; ++i) {
    cur += a[i];
    if (i >= k) cur -= a[i - k];
    if (i >= k - 1) best = max(best, cur);
}
```

## Complexity

Time — O(n) for the pointer/window family, O(n log n) once you sort.
Space — O(1), or O(n) if you materialise a prefix array.

## Gotchas

- Overflow: sums of `int` need `long long`.
- Window shrink condition goes in a `while`, not an `if`, when the constraint can be violated by more than one element.
- Empty array and `k > n` are separate base cases — check both.

## Problems

| Problem | Difficulty | Status |
| --- | --- | --- |
| Two Sum | Easy | |
| Maximum Subarray (Kadane) | Medium | |
| Longest Substring Without Repeating Characters | Medium | |
| Subarray Sum Equals K | Medium | |
| Trapping Rain Water | Hard | |

## Related

[[two-pointer]] · [[sliding-window]] · [[prefix-sum]] · [[binary-search]] · [[_index]]

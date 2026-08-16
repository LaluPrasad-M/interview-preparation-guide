# Binary Search Patterns

> [!tldr]
> Binary search works whenever the answer space is monotonic, which means the validity flips exactly once from false to true or true to false.

---

## The condition that makes it work

Monotonic means the pattern looks like one of these:

```text
false false false true true true
```

or

```text
true true true false false false
```

If you can define such a pattern, binary search applies.

### Case A: find the minimum valid answer

As `x` increases:

```text
x:        1  2  3  4  5  6  7
isValid:  F  F  F  T  T  T  T
```

Once it becomes true it stays true, so binary search finds the first T.

### Case B: find the maximum valid answer

```text
x:        1  2  3  4  5  6  7
isValid:  T  T  T  T  F  F  F
```

Once it becomes false it stays false, so binary search finds the last T.

---

## Universal template

```text
left = LOW
right = HIGH

while (left <= right) {
    mid = floor((left + right) / 2)

    if (isValid(mid)) {
        right = mid - 1   // or left = mid + 1
    } else {
        left = mid + 1    // or right = mid - 1
    }
}
```

The whole trick is choosing `LOW`, `HIGH`, `isValid`, and the direction.

---

## The fourteen problem types

| Type | Core idea | Example | Key condition |
| --- | --- | --- | --- |
| 1. Search in a sorted array | find the target | find 5 in `[1,3,5,7,9]` | compare mid with target, adjust low or high |
| 2. First or last occurrence | with duplicates | first 2 in `[1,2,2,2,3]` | adjust low or high based on whether mid satisfies the condition |
| 3. Search in rotated array | find in a rotated sorted array | find 0 in `[4,5,6,7,0,1,2]` | check which half is sorted, adjust accordingly |
| 4. Find peak element | greater than its neighbours | peak in `[1,2,3,1]` | compare mid with neighbours, move toward the larger one |
| 5. Find smallest or largest value | satisfying a condition | smallest k with `k^2 >= 10` | binary search on the range of possible values |
| 6. Allocate resources | minimise the maximum workload | allocate `[10,7,8,12]` to 3 workers | binary search on possible workloads |
| 7. Minimise or maximise time | under constraints | minimum speed k for Koko | binary search on possible speeds |
| 8. Find missing element | smallest missing in a sorted array | smallest missing in `[0,1,2,6,9]` | compare mid with its index |
| 9. Find square or cube root | to a precision | square root of 16 | search `[0, x]`, check if `mid^2` is close |
| 10. Search in 2D matrix | sorted matrix | find 5 in `[[1,3,5],[7,9,11]]` | treat as a flattened sorted array |
| 11. Find closest element | to a target | closest to 8 in `[1,3,5,7,9]` | compare mid with target, adjust |
| 12. Search in infinite array | unbounded sorted input | find 10 in `[1,2,3,...]` | expand the range exponentially, then binary search |
| 13. Median of two arrays | two sorted arrays | median of `[1,3]` and `[2]` | binary search to partition and balance halves |
| 14. Split array | into k subarrays, minimise the largest sum | split `[7,2,5,10,8]` into 2 | binary search on possible sums |

---

## Find the minimum in a rotated array

**Setup.** The array is sorted and rotated, no duplicates. Find the minimum in O(log n).

**Key insight.** At any index one half is always sorted, and the minimum lies in the unsorted half. Compare `nums[mid]` with `nums[right]`.

```text
if nums[mid] > nums[right]:
    minimum is in the right half
    -> l = mid + 1
else:
    mid CAN be the minimum
    -> r = mid
```

> [!warning] Do not use `r = mid - 1` here
> Because `mid` itself might be the answer. This is the difference between "search for a target" and "search for a boundary".

```text
while (l < r) {
    mid = (l + r) / 2
    if nums[mid] > nums[r]:
        l = mid + 1
    else:
        r = mid
}
return nums[l]
```

> [!tip] The golden rule
> If mid can be the answer, keep it with `r = mid`. If mid cannot be the answer, discard it with a plus or minus one.

**The interview line.** Since the middle element itself can be the minimum, we keep it in the search space and shrink toward it.

**Complexity.** Time O(log n), space O(1).

# Two Pointers

> [!tldr]
> Two indices moving in a coordinated way, so O(n^2) becomes O(n). It works because moving a pointer eliminates possibilities you can prove are useless.

---

## What it is

A strategy where two indices traverse the array in a coordinated way, reducing time complexity from O(n^2) to O(n).

---

## When it applies

Two observations must hold.

1. The data is sorted, or can be sorted, so monotonicity exists.
2. Moving a pointer causes a monotonic change, for example the area shrinking or the sum increasing.

The deciding factor is that pointer movement is guided by eliminating impossibilities.

---

## Why the movement rule works

**Pair sum in a sorted array.** If `arr[l] + arr[r] > target`, you must move `r` left, because moving `l` right would only increase the sum.

**Container with most water.** If `height[l] < height[r]`, moving `r` inward cannot increase the area, so move `l`.

In both cases you are not guessing. You are discarding a whole set of candidates that cannot beat what you already have.

---

## Templates

### Opposite ends

```python
l = 0; r = n - 1
while l < r:
    compute result
    adjust l or r
```

### Same direction

```python
slow = 0
for fast in range(n):
    if condition:
        swap / copy / count
        slow++
```

---

## Validated problem list

**Opposite end**

- Container With Most Water
- Two Sum II (sorted input)
- 3Sum
- 3Sum Closest
- 4Sum

**Same direction**

- Remove Duplicates from Sorted Array
- Remove Element
- Move Zeroes
- Sort Colors (Dutch flag)
- Merge Sorted Array

**Count, pair and greedy**

- Boats to Save People
- Minimum Absolute Difference
- Minimum Moves to Make Array Elements Equal II (median)
- Minimum Operations to Make Array Equal I (greedy)
- Assign Cookies and Candy (greedy pairing)
- Jump Game II (two pointer plus greedy)

> [!warning] Subarray product below K is not a two pointer problem
> It looks like one, but it is a counting sliding window problem. See [[sliding-window]].

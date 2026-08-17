# Prefix Sum and Hash Map

> [!tldr]
> When you need to count subarrays with an exact sum, you do not search for them. At every index you count how many earlier prefix sums differ from the current one by exactly k.

---

## The core identity

Build `prefix[j] = sum of nums[0..j]`.

Then:

```python
sum(nums[i..j]) = prefix[j] - prefix[i-1] = k
=> prefix[i-1] = prefix[j] - k
```

So for each index `j`, count how many earlier prefix sums equal `prefix[j] - k`. That is the whole solution.

---

## Why sliding window does not work here

Sliding window only works when both of these hold:

1. All numbers are non negative, and
2. The window can be shrunk based on a monotonic rule, for example sum above target means shrink.

With negative numbers, shrinking does not always decrease the sum, so there is no single rule for expanding and shrinking. Sliding window fails.

---

## The algorithm

Loop through the array, maintaining:

- `prefixSum`, the running sum up to the current index
- `map`, the frequency of every prefix sum seen so far
- `count`, the number of valid subarrays found

At each step: update `prefixSum`, check how many times `prefixSum - k` has appeared, add that to `count`, and only then add the current `prefixSum` to the map.

```python
map = {0: 1}      // base case: prefix sum 0 has been seen once
prefixSum = 0
count = 0

for num in nums:
    prefixSum += num

    if (prefixSum - k) in map:
        count += map[prefixSum - k]

    map[prefixSum] += 1
```

---

## Dry run

`nums = [1, 2, 3]`, `k = 3`.

| prefixSum | map before | map after | count |
| --- | --- | --- | --- |
| 0 | `{0:1}` | `{0:1}` | 0 |
| 1 | `{0:1}` | `{0:1, 1:1}` | 0 |
| 3 | `{0:1, 1:1}` | `{0:1, 1:1, 3:1}` | +1 because `3 - 3 = 0` |
| 6 | `{0:1, 1:1, 3:1}` | `{0:1, 1:1, 3:1, 6:1}` | +1 because `6 - 3 = 3` |

Result: 2, from the subarrays `[1, 2]` and `[3]`.

---

## Two mistakes that break it

> [!warning] `map[0] = 1` is mandatory
> Without it you never count subarrays that start at index 0, because a valid `[0..j]` with sum k has no earlier prefix to match against. This is the number one prefix sum mistake across every problem in this family.

> [!warning] Storing a prefix is not conditional
> This is wrong:
> ```js
> if (map.has(sum - k)) {
>     count += map.get(sum - k)
> } else {
>     map.set(sum, ...)   // wrong: only stores on a miss
> }
> ```
> Every prefix must be recorded, every time. Counting and storing are independent steps. The map is the complete history of prefix states, not a fallback.

---

## Reframing problems into this shape

**Count Nice Subarrays** asks for subarrays with exactly k odd numbers. Map odd to 1 and even to 0, and it becomes "count subarrays with sum k". That is the only reframing you need to remember.

Both approaches are valid there:

| Approach | How |
| --- | --- |
| Prefix sum plus hash map | directly counts exactly k |
| Sliding window | `exact(k) = atMost(k) - atMost(k-1)` |

---

## Common variants, same pattern

| Problem type | What changes |
| --- | --- |
| count subarrays with sum equals k | the base pattern |
| count subarrays with sum at most k | two pointer, or map plus balanced tree |
| count subarrays with sum below k | as above with adjustments |
| count subarrays with K distinct | distinct count instead of sum |
| count nice subarrays | identical, after the odd to 1 mapping |

---

## Complexity

Time O(n), space O(n) for the map.

---

## Edge cases

- Empty array gives 0.
- All zeros with `k = 0` gives many valid subarrays, `n * (n + 1) / 2`.
- Negative numbers mean sliding window is out.
- Prefix sums repeat, so accumulate frequency rather than overwriting.

---

## When to reach for this pattern

Use prefix sum plus hash map when the problem says count subarrays, the condition is an exact sum or count, the numbers may be 0/1 or negative, and multiple valid subarrays can overlap.

Never use a plain sliding window when you are counting exactly k, when removing an element can either increase or decrease validity, or when there is no monotonic shrink rule.

---

## The sentence to remember

At every index, count how many earlier prefix sums make the current sum differ by k. If that sentence makes sense, you can rederive the solution any time.

The mantra, in two lines:

```python
count += freq[prefixSum - k]
freq[prefixSum]++
```

---

## Problem list

- Subarray Sum Equals K
- Continuous Subarray Sum
- Subarray Sums Divisible by K
- Longest Well Performing Interval
- Longest Balanced Subarray (equal zeros and ones)
- Count Nice Subarrays
- Pivot Index
- Longest Subarray with Equal Letters and Digits

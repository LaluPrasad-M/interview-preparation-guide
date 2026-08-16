# Sliding Window

> [!tldr]
> Two pointers plus an invariant. You expand with `right`, and shrink with `left` the moment the window stops being valid.

---

## What it is

A technique for processing contiguous ranges using two indices that keep a valid window while scanning once, in O(n).

Instead of recomputing everything for each subarray, you update the state incrementally when the window grows or shrinks.

---

## When it applies

**The problem is about contiguous subarrays.** Look for the words subarray, substring, window, continuous sequence.

**The state can be updated incrementally.** Sum, product, frequency map, distinct count, and max or min with a deque all qualify.

---

## The core theory

Sliding window is two pointers plus an invariant.

- `right` expands the window
- `left` shrinks the window when it becomes invalid

As you slide you maintain a window invariant, which is the answer to "what makes a window valid or invalid?".

Examples of invariants: sum at most k, product below k, distinct characters at most k, counts cover the target, at most k zeros.

If the invariant breaks, shrink from the left until it is restored.

---

## Templates

### Fixed window

```text
for right in range(n):
    add nums[right]
    if window > k:
        remove nums[left]
        left++
    update answer
```

### Variable window, expand and shrink

```text
left = 0
for right in range(n):
    add nums[right]
    while condition violated:
        remove nums[left]
        left++
    update answer
```

### Frequency window

```text
left = 0
for right in range(n):
    freq[s[right]]++
    while condition violated:
        freq[s[left]]--
        left++
    if valid:
        update answer
```

---

## The six sub variants

### 1. Fixed size window

Window size is `k`, given explicitly. No shrinking logic; you add the incoming element and remove the outgoing one.

Examples: maximum average subarray of size k, maximum sum subarray of size k, maximum vowels in a substring of size k.

### 2. Variable window, longest valid

The window expands and sometimes shrinks to stay valid.

Triggers: "longest substring with at most or at least", "longest subarray with sum at most k", "longest with at most K distinct characters".

Examples: longest substring without repeating characters, fruit into baskets, longest ones with at most K flips.

### 3. Variable window, minimum window

The opposite of longest: find the smallest window that satisfies the condition. Shrinking becomes the priority.

Example: minimum window substring.

### 4. Counting subarrays

You need neither longest nor shortest, only the count of subarrays satisfying a constraint.

The key idea: when a window is valid, every subwindow with the same right bound is also valid.

Examples: subarrays with product below k, binary subarrays with sum k, count nice subarrays.

### 5. Frequency based windows

Used with strings, needs frequency maps and a "need to have" count.

Examples: find all anagrams, permutation in string, minimum window substring.

### 6. Monotonic window

Maintains the window maximum or minimum in O(n) using a deque that keeps indices in decreasing order.

Example: sliding window maximum.

---

## Decision tree

**Q1: is it about contiguous subarrays?** If no, this is not a sliding window problem.

**Q2: what do they want?**

| They want | Use |
| --- | --- |
| max length | variable window, longest |
| min length | variable window, minimum |
| fixed k | fixed window |
| just a count | counting subarrays |
| substrings matching a pattern | frequency window |
| max or min inside the window | deque |

**Q3: what is the invariant?** Sum at most k, product below k, distinct at most k, zero count at most k, frequency map covers target. This is the core of the whole technique.

---

## The exact k trick

> [!tip] Sliding window gives you "at most K" for free
> If the problem asks for exactly K, convert it: `exact(K) = atMost(K) - atMost(K-1)`.

---

## Validated problem list

**Fixed window**

- Maximum Average Subarray I
- Maximum Vowels in Substring
- Contains Duplicate II

**Variable window, longest**

- Longest Substring Without Repeating Characters
- Fruits Into Baskets (longest with at most 2 distinct)
- Longest Repeating Character Replacement
- Max Consecutive Ones III
- Minimum Size Subarray Sum (shortest at or above sum)

**Frequency and permutation**

- Find All Anagrams in a String
- Permutation in String

**Minimum cover**

- Minimum Window Substring

**Counting subarrays**

- Binary Subarrays With Sum
- Count Nice Subarrays
- Subarrays With Product Less Than K
- Subarrays Divisible by K (prefix hybrid)
- Find the Longest Equal Subarray

**Monotonic**

- Sliding Window Maximum

---

## The one line summary

Sliding window gives you "at most K" for free. If the problem asks for exactly K, convert it using the at most difference.

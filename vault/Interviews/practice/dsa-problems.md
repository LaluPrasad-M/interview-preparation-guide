# Problem Lists with Mental Triggers

> [!tldr]
> The revision list. Each row is a problem plus the one sentence that unlocks it, so you can test recall without opening the editor.

> [!tip] The execution rule
> If you stare at one of these for five minutes and draw a complete blank, stop. Go straight to your previous submissions, look at your working code, and read it until you say "ah, right".

---

## Linear structures: arrays, strings, pointers, stacks

Moving left to right and optimising O(N^2) brute forces down to O(N).

| ID | Problem | The core mental trigger |
| --- | --- | --- |
| 238 | Product of Array Except Self | **Prefix and suffix.** Two passes. Store the running product from the left, then multiply by the running product from the right. |
| 128 | Longest Consecutive Sequence | **Hash set.** Put everything in a set. Only start a while loop if `num - 1` does not exist in the set. |
| 15 | 3Sum | **Sort plus two pointers.** Sort it. For loop the first number, then standard Two Sum II with left and right pointers for the rest. |
| 3 | Longest Substring Without Repeats | **Sliding window.** `left` and `right` pointers. Expand `right`. If there is a duplicate, shrink `left` until the duplicate is gone. |
| 76 | Minimum Window Substring | **The window template.** Track `have` against `need`. Expand `right` until valid, then shrink `left` to find the minimum. |
| 206 | Reverse Linked List | **The 3 pointers.** `prev`, `curr`, `next`. Save `next`, flip `curr.next` to `prev`, step them all forward. |
| 146 | LRU Cache | **Map plus DLL.** Hash map for O(1) lookup, doubly linked list for O(1) move to front. |
| 20 | Valid Parentheses | **Standard stack.** Push opens. On a close, pop and check whether it is the matching pair. |
| 496 | Next Greater Element I | **Monotonic stack.** Store numbers in a stack. If you see a bigger number, pop the stack, that is their answer. |

---

## Branching and searching: trees, graphs, recursion, DP

State spaces, recursion, and avoiding doing the same work twice.

| ID | Problem | The core mental trigger |
| --- | --- | --- |
| 33 | Search in Rotated Array | **Modified binary search.** Find which half is strictly sorted first, then ask: is my target mathematically inside that sorted half? |
| 74 | Search a 2D Matrix | **1D to 2D maths.** Binary search from 0 to `m*n - 1`. The row is `mid / cols`, the column is `mid % cols`. |
| 102 | Binary Tree Level Order | **BFS queue.** `queue.push(root)`. Inside the while, capture `queue.length` first, then loop exactly that many times. |
| 236 | LCA of a Binary Tree | **Post order DFS.** If you are `p` or `q`, return yourself. If the left and right branches both return something, you are the LCA. |
| 200 | Number of Islands | **Grid traversal.** Double for loop. When you see a 1, increment the count and run DFS or BFS to turn the whole island to zeros. |
| 46 | Permutations | **Backtracking, all paths.** The loop always starts at 0. Use a `visited` array so you do not pick the same index twice. |
| 39 | Combination Sum | **Backtracking, subset.** The loop starts at `index`. Pick it and recurse with `i`, since reuse is allowed, then pop it. |
| 198 | House Robber | **1D DP.** At any house the choice is `max(rob current + dp[i-2], skip current + dp[i-1])`. |
| 416 | Partition Equal Subset Sum | **0/1 knapsack.** The target is `sum / 2`. Top down DP caching `(index, currentSum)`. |

---

## Linked lists and stacks, the revision set

**The linked list core: dummy nodes and pointers.**

| ID | Problem | The core mental trigger |
| --- | --- | --- |
| 206 | Reverse Linked List | **The 3 pointers.** `prev`, `curr`, `next`. Save `next`, flip `curr.next` to `prev`, step them all forward. |
| 141 | Linked List Cycle | **Floyd's tortoise and hare.** `slow` moves 1 step, `fast` moves 2. If they ever equal each other, there is a cycle. |
| 21 | Merge Two Sorted Lists | **The dummy node.** Create `let dummy = new ListNode()`. Point `curr` to the smaller value of the two lists, then step forward. |

**The stack core: LIFO execution and state.**

| ID | Problem | The core mental trigger |
| --- | --- | --- |
| 20 | Valid Parentheses | **Standard push and pop.** Push opening brackets. On a closing bracket, pop the stack and check whether they match. |
| 155 | Min Stack | **The two stack pattern.** One normal stack for numbers, one stack strictly for tracking the minimum seen so far. |
| 150 | Evaluate Reverse Polish Notation | **The calculator.** If it is a number, push it. If it is an operator, pop the top two numbers, do the maths, push the result back. |

---

## Coverage check by pattern

The list above is meant to cover every array interview pattern:

Two pointers, sliding window, prefix sum plus hash, sorting plus greedy, Kadane and max subarray, binary search on the answer, monotonic stack, and heap or top K.

For heaps specifically, two more are worth adding: Top K Frequent Elements and Kth Largest Element in an Array.

---

## The prefix sum, sorting and greedy set

**Prefix sum plus hash.** Subarray Sum Equals K, Continuous Subarray Sum, Subarray Sums Divisible by K, Longest Well Performing Interval, Longest Balanced Subarray, Count Nice Subarrays, Pivot Index, Longest Subarray with Equal Letters and Digits.

**Sorting plus greedy.** Longest Consecutive Sequence, Min Increment For Unique, Merge Intervals, Non Overlapping Intervals, Partition Labels, Task Scheduler.

**Kadane and variants.** Maximum Subarray, Maximum Circular Subarray, Best Time to Buy and Sell Stock, Stock II with multiple transactions.

**Binary search on the answer.** Koko Eating Bananas, Ship Packages Within D Days, Split Array Largest Sum, Smallest Divisor Given a Threshold.

**Monotonic stack.** Next Greater Element I and II, Daily Temperatures, Asteroid Collision, Largest Rectangle in Histogram, Trapping Rain Water.

---

## A worked classic: minimum size subarray sum

The problem: given an array of positive integers and a target sum, find the minimal length of a contiguous subarray whose sum is at or above the target. Return 0 if no such subarray exists.

For `target = 7`, `nums = [2,3,1,2,4,3]`, the expected result is 2, from the subarray `[4,3]`.

The reasoning written out during the interview:

```text
Max(sum) Min(size of array)   // multiple answers, so track the minimum
P[i] - ? = target             // i - j gives the minima, O(n)
sliding window
```

```js
let nums = [2, 3, 1, 2, 4, 3]
let target = 7
let r = 0, min = Infinity, sum = 0
for (let l = 0; l < nums.length; l++) {
  sum += nums[l]
  while (sum >= target) {
    min = Math.min(min, l - r + 1)
    sum = sum - nums[r]
    r++
  }
}
console.log(min)
```

---

## A second worked classic: jump game II

You are given a 0 indexed array `nums` of length `n` and start at `nums[0]`.

Each element `nums[i]` is the maximum length of a forward jump from index `i`. From `nums[i]` you can jump to any `nums[i + j]` where `0 <= j <= nums[i]` and `i + j < n`.

Return the minimum number of jumps to reach `nums[n - 1]`. You may assume it is always possible.

| Input | Output | Explanation |
| --- | --- | --- |
| `[2, 3, 1, 1, 4]` | 2 | jump 1 step from index 0 to 1, then 3 steps to the last index |
| `[2, 3, 0, 1, 4]` | 2 | |
| `[1, 1, 1, 1]` | 3 | |
| `[0]` | 0 | already at the last index |

Constraints: `1 <= nums.length <= 10^4`, `0 <= nums[i] <= 1000`, and reaching the end is guaranteed.

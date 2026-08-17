# Monotonic Stack, Problems and Reference

> [!tldr]
> The problem list organized by category, common traps, and the monotonic deque pattern for sliding window problems.

Part of [[monotonic-stack]].

---

## Problem list

**Next greater or smaller**

- 496 Next Greater Element I
- 503 Next Greater Element II (circular)

**Range and histogram**

- 84 Largest Rectangle in Histogram
- 85 Maximal Rectangle

**Temperature**

- 739 Daily Temperatures

**Stock and prices**

- 901 Online Stock Span

**Structural**

- 42 Trapping Rain Water

**Array bounds and contribution**

- 907 Sum of Subarray Minimums
- 2104 Sum of Subarray Ranges

Plus: Asteroid Collision, Remove Duplicate Letters, Car Fleet.

Mapping problems to stack order:

| Problem | Question | Stack |
| --- | --- | --- |
| Daily Temperatures | next warmer | decreasing |
| Next Greater Element | next greater | decreasing |
| Stock Span | previous greater | decreasing |
| Histogram | next smaller | increasing |
| Trapping Rain Water | both sides | both |

---

## Traps

Wrong reasoning sounds like "use an increasing stack because the numbers increase", or "it depends on the values", or "try both and see".

Correct reasoning: I want to resolve smaller elements when a larger one arrives, so I use a decreasing stack.

---

## Monotonic deque, the sibling

When an array problem uses a sliding window with left and right, and you need the current minimum or maximum while both expanding and shrinking, a monotonic deque is the right tool.

The reason is that the old values matter too, not just the one entering now. A stack can only reach its top, never its oldest element.

### Worked example: shortest subarray with sum at least K

1. Convert to prefix sums. `prefix[i] = nums[0] + ... + nums[i-1]`, so `nums[start..end] = prefix[end+1] - prefix[start]`.
2. For each `end`, find `start` such that `prefix[end+1] - prefix[start] >= K` and the length is minimal. The prefix at `start` should be as small as possible and `start` as large as possible, so the largest valid start gives the shortest subarray.
3. Keep a deque of candidate start indices where indices increase and prefix values increase.
4. **Front pop rule.** While `prefix[i] - prefix[deque[0]] >= K`, update the answer with `i - deque[0]` and pop the front. Since the newer `i` is bigger and satisfies the condition, the older value at the front can never give a better answer later.
5. **Back pop rule.** While `prefix[i] <= prefix[deque.back]`, pop the back. The plan is to find a bigger `i` with a smaller prefix, so an earlier start with a higher prefix is always worse.
6. Push the current index.
7. If the answer was never touched, return -1.

```js
var shortestSubarray = function(nums, k) {
    const n = nums.length;

    // STEP 1: Build prefix sum
    const prefix = new Array(n + 1).fill(0);
    for (let i = 0; i < n; i++) {
        prefix[i + 1] = prefix[i] + nums[i];
    }

    // This deque will store indices of the prefix array
    const deque = [];

    // This will store the shortest length found
    let ans = Infinity;

    // STEP 2: Iterate over all prefix indices
    for (let i = 0; i <= n; i++) {

        // CASE A: Deque is empty, no starting index to compare with
        if (deque.length === 0) {
            deque.push(i);
            continue;
        }

        // CASE B: Try to shrink from the FRONT
        // check whether the earliest start index forms a valid subarray ending at i
        while (
            deque.length > 0 &&
            prefix[i] - prefix[deque[0]] >= k
        ) {
            const startIndex = deque[0];
            const length = i - startIndex;

            ans = Math.min(ans, length);

            // This start index can never give a shorter answer later
            deque.shift();
        }

        // CASE C: Clean useless start indices from the BACK
        // remove old starts that are worse than current i
        while (
            deque.length > 0 &&
            prefix[i] <= prefix[deque[deque.length - 1]]
        ) {
            deque.pop();
        }

        // CASE D: Add current index as a future start candidate
        deque.push(i);
    }

    return ans === Infinity ? -1 : ans;
};
```

---

## The interview line

I use a monotonic decreasing stack of indices to track unresolved days. When a warmer day appears, I pop indices from the stack and compute the waiting time. Each index is processed once, giving O(n) time.

Final takeaway: monotonic stacks are about deferring decisions. They are not about sorting. They are about resolving future dependencies efficiently.

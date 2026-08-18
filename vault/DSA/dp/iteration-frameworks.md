# Non Standard DP Iteration Frameworks

> [!tldr]
> Three loop skeletons for when a plain forward loop does not work. The trigger is always the direction your state depends on.

---

## 1. Interval DP, the diagonal or gap iteration

**The trigger.** The problem asks for the max, min or longest of a contiguous subarray or substring, and you can only solve a large chunk by breaking it into smaller inner chunks, or by combining two adjacent chunks.

**The dependency.** `dp[i][j]` depends on `dp[i+1][j-1]`, the inside, or it splits at some point `k` and relies on `dp[i][k]` and `dp[k+1][j]`.

**Classic questions.** Longest Palindromic Subsequence, Burst Balloons, Minimum Cost to Merge Stones.

You must iterate by the size of the interval, the gap, so smaller inner intervals are generated before larger outer ones.

```ts
// 1. Outer loop dictates the size of the subarray (gap between i and j)
for (let gap = 0; gap < n; gap++) {

    // 2. Inner loop dictates the start position
    // It stops early so 'j' doesn't go out of bounds
    for (let i = 0; i < n - gap; i++) {

        // 3. Mathematically calculate the end position
        let j = i + gap;

        if (gap === 0) {
            // Base case: length 1
            dp[i][j] = ...
        } else if (gap === 1) {
            // Base case: length 2
            dp[i][j] = ...
        } else {
            // Core logic: dp[i][j] safely relies on dp[i+1][j-1]
            // because a gap of size N safely relies on a gap of size N-2
            dp[i][j] = dp[i+1][j-1] ...
        }
    }
}
```

---

## 2. Game theory or future DP, the reverse iteration

**The trigger.** You are playing a game against an optimal opponent, or you are making a decision today where the payoff depends entirely on what happens tomorrow.

**The dependency.** State `i` (today) depends on `i+1` or `i+2` (tomorrow). State 0, the start, needs the answer to state `n`, the end.

**Classic questions.** House Robber when conceptualised as "if I rob house i, I add the max profit from i+2", the Stone Game series, Decode Ways.

You must iterate backwards from the end of the array to the beginning, generating the future values first so the past can use them.

```ts
// Base cases usually sit at the very end of the array
dp[n] = ...
dp[n-1] = ...

// 1. Iterate strictly backwards
for (let i = n - 2; i >= 0; i--) {

    // 2. Safe to look ahead because the future was already computed
    let choice1 = arr[i] + dp[i + 2];
    let choice2 = dp[i + 1];

    dp[i] = Math.max(choice1, choice2);
}
```

---

## 3. Bitmask DP, the subset iteration

**The trigger.** The problem gives a very small constraint, `N <= 20`, and asks for the optimal way to group things, visit things, or pair things up.

**The dependency.** A state representing a set of items, for example items A, B and C as binary `111`, depends on a smaller subset of those items, for example A and B as `011`.

**Classic questions.** Travelling Salesperson Problem, Matchsticks to Square.

You do not iterate over the array indices. You iterate over integers from 0 to `2^N - 1`. Because 3 (binary `011`) is mathematically smaller than 7 (`111`), a standard counting loop naturally guarantees the smaller subsets are calculated before the larger ones.

```ts
let maxMask = 1 << n; // 2^n

// 1. Outer loop counts through every possible combination of elements
for (let mask = 0; mask < maxMask; mask++) {

    // 2. Inner loop checks individual elements within the current subset
    for (let i = 0; i < n; i++) {

        // If the i-th bit is ON in this mask
        if ((mask & (1 << i)) !== 0) {

            // Turn off the i-th bit to look at the previous subset
            let prevMask = mask ^ (1 << i);

            // Safe to rely on prevMask because prevMask is mathematically smaller than mask
            dp[mask] = Math.min(dp[mask], dp[prevMask] + cost[i]);
        }
    }
}
```

---

## How to pick one in an interview

Execute the boundary framework as usual: logic, then bounds, then out of range. But when you hit the dependency bound, ask one temporal question about your state machine.

| Question | Loop |
| --- | --- |
| Does my current state depend on the **left**? | standard forward loop, 0 to n |
| Does my current state depend on the **right**? | reverse loop, n down to 0 |
| Does my current state depend on the **inside**? | diagonal or gap loop, gap 0 to n |
| Does my current state depend on a **smaller combination**? | bitmask loop, 0 to 2^n |

Once you answer that, you plug in the memorised loop skeleton and spend the rest of your energy on the `if`/`else` logic inside it.

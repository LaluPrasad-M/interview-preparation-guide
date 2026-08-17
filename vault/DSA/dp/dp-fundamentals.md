# Dynamic Programming Fundamentals

> [!tldr]
> DP is recursion plus memory. Answer four questions (state, decision, transition, base case) and the code writes itself.

---

## What DP actually is

DP is recursion plus memory. Two conditions must hold: the problem has overlapping subproblems, and optimal substructure exists.

---

## The four question loop

For any DP problem you answer only these:

1. What is the STATE?
2. What is the DECISION?
3. What is the TRANSITION?
4. What is the BASE CASE?

If you can answer these, the DP code writes itself.

**Tiny example, climbing stairs with 1 or 2 steps.**

| Question | Answer |
| --- | --- |
| State | `dp[i]` is the number of ways to reach step i |
| Decision | come from `i-1` or `i-2` |
| Transition | `dp[i] = dp[i-1] + dp[i-2]` |
| Base | `dp[0] = 1`, `dp[1] = 1` |

That is DP. Nothing fancy.

---

## The mental flow

```python
START
 |
Is there recursion?
 |
Are subproblems repeating?
 |
Can I cache results?
 |
Define dp STATE
 |
Define TRANSITION
 |
Choose Bottom-Up or Memoization
 |
CODE
```

If you get stuck, write the recursion first, then memoize it.

---

## Doing nothing is a valid base case

In DP, doing nothing is often a valid base case and counts as one path.

If you reject this idea, many DP problems stop making sense: coin change, subset sum, decode ways, knapsack. In all of them `dp[0] = 1`.

---

## The five code patterns

### Pattern 1: 1D DP, linear

**Recognise it by.** An array, choices depending on the previous one or two states, and the keywords max, min or ways.

**Formula.** `dp[i]` is the best answer ending at `i`.

```js
const dp = Array(n).fill(0);
dp[0] = base;

for (let i = 1; i < n; i++) {
  dp[i] = transition(dp[i - 1], dp[i - 2]);
}

return dp[n - 1];
```

**Problems.** Climbing Stairs, House Robber, Fibonacci, Min Cost Climbing Stairs.

### Pattern 2: 2D DP, grid or matrix

**Recognise it by.** A grid, moving right or down, counting paths or minimum cost.

**Formula.** `dp[r][c]` is the best way to reach cell `(r, c)`.

```js
const dp = Array.from({ length: m }, () => Array(n).fill(0));

dp[0][0] = grid[0][0];

for (let r = 0; r < m; r++) {
  for (let c = 0; c < n; c++) {
    if (r === 0 && c === 0) continue;
    dp[r][c] =
      Math.min(
        r > 0 ? dp[r - 1][c] : Infinity,
        c > 0 ? dp[r][c - 1] : Infinity
      ) + grid[r][c];
  }
}

return dp[m - 1][n - 1];
```

**Problems.** Unique Paths, Min Path Sum, Dungeon Game.

### Pattern 3: pick or not pick, subset DP

**Recognise it by.** Choose or skip, subsets, knapsack vibes.

**Formula.** `dp[i][sum]` is whether we can form `sum` using the first `i` items.

```js
const dp = Array(target + 1).fill(false);
dp[0] = true;

for (let num of nums) {
  for (let s = target; s >= num; s--) {
    dp[s] = dp[s] || dp[s - num];
  }
}

return dp[target];
```

**Problems.** Subset Sum, Partition Equal Subset, Coin Change.

### Pattern 4: string DP

**Recognise it by.** Two strings, edit, match or subsequence.

**Formula.** `dp[i][j]` is the answer for `s1[0..i]` and `s2[0..j]`.

```js
const dp = Array.from({ length: m + 1 }, () =>
  Array(n + 1).fill(0)
);

for (let i = 1; i <= m; i++) {
  for (let j = 1; j <= n; j++) {
    if (s1[i - 1] === s2[j - 1]) {
      dp[i][j] = 1 + dp[i - 1][j - 1];
    } else {
      dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]);
    }
  }
}

return dp[m][n];
```

**Problems.** LCS, Edit Distance, Longest Palindromic Subsequence.

### Pattern 5: DP on decision or game

**Recognise it by.** Players, optimal play, minimax style.

**Formula.** `dp[i]` is the best score the current player can achieve.

**Problems.** Predict the Winner, Stone Game.

---

## Four mental models

| Model | Meaning | Example |
| --- | --- | --- |
| A: ending at i | most array DP, `dp[i]` is the answer ending at i | max subarray, LIS |
| B: till i, j | grid and string DP, `dp[i][j]` is the answer till positions i and j | LCS, Unique Paths |
| C: pick or not pick | subset or knapsack, take it or skip it | Coin Change, Partition |
| D: decision tree plus memo | write the recursion, cache on `(index, state)` | DP with constraints |

Reference problem: [longest increasing subsequence](https://leetcode.com/problems/longest-increasing-subsequence/description/).

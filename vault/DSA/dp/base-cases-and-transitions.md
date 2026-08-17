# DP Base Cases and Transitions

> [!tldr]
> There is no universal `dp[0]`. The base case is whatever your state definition says the answer is for the smallest input. Count problems start at 1, cost problems start at 0.

---

## The one rule

> [!tip] The rule that ends the confusion
> `dp[i]` must correctly answer the question you asked in the state definition, for the smallest possible inputs.

There is no universal `dp[0]` or `dp[1]`. They depend entirely on what `dp[i]` means.

---

## Always start with the state

Before touching base cases, finish this sentence:

> `dp[i]` means ____________________

If you cannot fill that in clearly, base cases will feel random.

---

## Three problems, side by side

### Climbing Stairs, counting ways

**State.** `dp[i]` is the number of ways to reach step `i`.

**`dp[0]`.** How many ways are there to reach step 0? Exactly one, do nothing. So `dp[0] = 1`.

**`dp[1]`.** How many ways to reach step 1? Only one, a single step. So `dp[1] = 1`.

Both base cases directly answer the state question.

### Minimum Cost Climbing Stairs

**State.** `dp[i]` is the minimum cost to reach step `i`. Notice this is about cost, not ways.

The problem says you can start at step 0 or step 1, you pay a cost only when stepping on a stair, and starting is free.

**`dp[0]`.** What is the minimum cost to reach step 0? You are allowed to start there and you have not stepped on anything, so `dp[0] = 0`.

**`dp[1]`.** Same reasoning, so `dp[1] = 0`.

This does not mean `cost[1]` is ignored forever. It means the cost is paid when you use that step to move forward.

### House Robber

**State.** `dp[i]` is the maximum money that can be robbed from houses `0..i`. This is a range result, not a position or movement, which is a big difference.

**`dp[0]`.** The maximum from house 0 alone: rob it, so `dp[0] = nums[0]`.

**`dp[1]`.** The maximum from houses 0 and 1: you cannot rob both, so pick the richer, `dp[1] = max(nums[0], nums[1])`.

Here you are not starting for free, you are making choices immediately.

### The comparison

| Problem | `dp[i]` means | `dp[0]` | `dp[1]` | Why |
| --- | --- | --- | --- | --- |
| Climbing Stairs (ways) | number of ways to reach i | 1 | 1 | the empty path counts |
| Min Cost Climbing | minimum cost to reach i | 0 | 0 | starting is free |
| House Robber | max money from 0..i | `nums[0]` | `max(nums[0], nums[1])` | you must choose |

> [!tip] The rule to tattoo on your brain
> Count problems have base cases of 1. Cost problems have base cases of 0.

---

## Climbing Stairs, the four questions in full

**1. State.** `dp[i]` is the number of valid ways, meaning sequences of moves, to reach step `i`. This counts paths and sequences, not physical stairs, so "reach step i" means the sum of moves equals `i`.

**2. Decision.** Where could I have come from? A 1 step move from `i - 1` or a 2 step move from `i - 2`. There are no other legal moves.

**3. Transition.** `dp[i] = dp[i - 1] + dp[i - 2]`. Every path to `i` ends with either a plus one move from `i-1` or a plus two move from `i-2`, and those two sets of paths do not overlap, so you can add them.

**4. Base case.** `dp[0] = 1` for the one empty sequence, and `dp[1] = 1` for the only path `[1]`. `dp[0] = 1` is what allows paths that start with a plus two jump; without it `dp[2]` would be wrong.

**The line to say.** "For Climbing Stairs, I define `dp[i]` as the number of ways to reach step i. At each step I can come from `i-1` or `i-2`, so the transition is `dp[i] = dp[i-1] + dp[i-2]`. The base cases are `dp[0] = 1` and `dp[1] = 1`."

Pattern: 1D DP ending at i, time O(n), space O(n), optimisable to O(1).

---

## Minimum Cost Climbing Stairs, in full

**In one sentence.** You pay `cost[i]` when you step on stair `i`, and you want the minimum total cost to reach the top. You can start from step 0 or step 1 for free.

**State.** `dp[i]` is the minimum cost required to reach step `i`. Not the number of ways, not the cost of step `i`, not the cost to stand on step `i`. It is the cost paid so far before stepping on `i`.

**Base cases.** `dp[0] = 0` and `dp[1] = 0`, because you can step directly on either without touching any other stair, so nothing has been paid.

Wrong assumptions to avoid: `dp[0] = cost[0]`, `dp[1] = cost[1]`, or `dp[0] = 1` which belongs to Climbing Stairs.

**Decision.** To reach step `i` you can only come from `i - 1` or `i - 2`.

**Transition.**

```python
dp[i] = min(
  dp[i - 1] + cost[i - 1],
  dp[i - 2] + cost[i - 2]
)
```

The intuition to memorise: cost so far plus the cost of the step I just used. You pay for the step you land on, not the step you are going to.

**Final answer.** `return dp[n]`, because `n` represents the top, the top has no cost, and costs are paid only on actual stairs.

```js
var minCostClimbingStairs = function(cost) {
    const n = cost.length;
    const dp = new Array(n + 1).fill(0);

    dp[0] = 0;
    dp[1] = 0;

    for (let i = 2; i <= n; i++) {
        dp[i] = Math.min(
            dp[i - 1] + cost[i - 1],
            dp[i - 2] + cost[i - 2]
        );
    }

    return dp[n];
};
```

> [!warning] The five mistakes here
> Using `dp[0] = 1`. Treating this like Climbing Stairs and counting ways. Adding `cost[i]` instead of `cost[i-1]` and `cost[i-2]`. Forgetting you can start from step 1 for free. Returning `dp[n-1]` instead of `dp[n]`.

**The line to say.** "I define `dp[i]` as the minimum cost to reach step i. Since I can start at step 0 or 1 for free, both base cases are zero. To reach step i I can come from `i-1` or `i-2` and pay the cost of the step I land on. I take the minimum of those two and return `dp[n]`."

---

## House Robber, deriving the transition

**In one sentence.** Houses in a line, robbing one means you cannot rob the adjacent one, maximise total money.

**State.** `dp[i]` is the maximum money that can be robbed from houses `0..i`.

This definition is crucial. It describes a range result, not a decision. It does not force robbing house `i`, and it allows both robbing and skipping. Define the state wrongly and you cannot derive the transition.

**The two choices at house i.** There are exactly two, no more, no less.

**Choice 1, skip house i.** Your total money does not change, and the best money you already had up to house `i-1` is still valid.

```python
money_if_skip = dp[i - 1]
```

**Choice 2, rob house i.** You cannot rob `i-1`, so the last house you could have robbed is at most `i-2`. Add the money in the current house.

```python
money_if_rob = dp[i - 2] + nums[i]
```

**Why only these two exist.** There is no robbing half a house, no robbing `i` and `i-1`, and no robbing `i` and `i-3` but not `i-2`. The constraint strictly limits the decision space, which makes this binary choice DP: take it or skip it.

**Why the transition is a max.** Your goal is to maximise money, not minimise cost or count paths.

```python
dp[i] = max(
  dp[i - 1],
  dp[i - 2] + nums[i]
)
```

This formula is not magic, it is a direct translation of the two physical choices.

> [!warning] Why `dp[i-1]` does not violate the adjacency rule
> `dp[i-1]` does not mean "I robbed house i-1". It means "this is the best money possible considering houses up to i-1". That best solution may or may not include house `i-1`, so using it when skipping house `i` is always safe.

```js
var rob = function(nums) {
    const n = nums.length;
    if (n === 0) return 0;
    if (n === 1) return nums[0];

    const dp = new Array(n).fill(0);
    dp[0] = nums[0];
    dp[1] = Math.max(nums[0], nums[1]);

    for (let i = 2; i < n; i++) {
        dp[i] = Math.max(
            dp[i - 1],          // skip
            dp[i - 2] + nums[i] // rob
        );
    }

    return dp[n - 1];
};
```

---

## Same indices, different meanings

| Problem | What `dp[i]` represents | Transition logic |
| --- | --- | --- |
| Climbing Stairs (ways) | count of paths | add all valid paths |
| Min Cost Climbing | min cost so far | add the cost of the step |
| House Robber | best result so far | choose the max of valid decisions |

---

## The universal derivation template

When deriving a DP transition, always ask:

1. What does `dp[i]` mean in plain English?
2. At position `i`, what are my legal choices?
3. If I make a choice, which previous state is valid?
4. Do I add something or compare something?

Follow these and the formula emerges naturally.

---

## The formal framework

**Golden rule.** Transitions are derived from the state definition, never memorised. If the state changes, the transition must change.

**Step 1, define the state.** `dp[x]` answers one precise question. If it is vague the transition will be wrong.

**Step 2, enumerate all legal ways to reach state x.** What are the only valid previous states that can lead to `x`? This is a graph question: nodes are states, edges are legal transitions. DP is just a shortest or longest path on an implicit DAG.

**Step 3, determine how the value changes along an edge.** For each `prev -> x`: do I add cost, add a count, take max or min, or carry the value forward unchanged? This decides the operator.

**Step 4, aggregate all valid transitions.** Counting means sum. Optimisation means min or max. Feasibility means OR or AND.

---

## Canonical transition patterns

### A: counting DP, ways and paths

```python
dp[x] = sum(dp[prev])
```

Used when counting sequences or paths. Example, Climbing Stairs: `dp[i] = dp[i-1] + dp[i-2]`. All valid paths contribute and there is no cost comparison.

### B: min or max cost DP, accumulation

```python
dp[x] = min/max(dp[prev] + cost(prev -> x))
```

Used when a cost is paid during movement. Example, Min Cost Climbing Stairs. Each edge has a weight and you choose the cheapest path.

### C: choice or skip DP, binary decision

```python
dp[x] = max/min(
  skip_current,
  take_current
)
```

Used when a constraint forbids adjacent selection. Example, House Robber. Two mutually exclusive legal actions, compare the outcomes.

### D: feasibility DP, true or false

```python
dp[x] = OR / AND(dp[prev])
```

Used for subset sum, partition, and validity checks. Example: `dp[i][sum] = dp[i-1][sum] OR dp[i-1][sum-nums[i]]`.

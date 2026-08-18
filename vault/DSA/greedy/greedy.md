# Greedy Algorithms

> [!tldr]
> Take the best local choice at every step and never look back. It only works if that local choice provably does not damage a future one.

---

## The defining trait

A greedy algorithm makes the best possible choice right now, a local optimum, assuming this leads to the best overall outcome, a global optimum, and it never looks back.

Characteristics: no backtracking, no reconsideration, no dynamic programming state. Usually one pass, or a sort plus one pass.

Examples: picking the smallest coin first, pairing the heaviest with the lightest, picking the earliest finishing meeting.

---

## Worked example: the Jump Game

The greedy behaviour lives on one line:

```ts
farthest = Math.max(farthest, i + nums[i])
```

**Always grab the farthest reach.** At every single step you ask "can this spot push my boundary further?" If yes, you take the new boundary right away.

**No long term planning.** You do not care how you get to that boundary. You do not evaluate whether jumping 2 steps now sets up a better jump later than jumping 1 step.

**No regrets, no backtracking.** Once you pass an index you never reconsider it. If index 1 gave you a reach of 4 and index 2 only gives you 3, you keep the 4 and move on. You never undo choices.

It is greedy in the way a person grabs the largest dollar bill in front of them at every step, without worrying whether skipping a dollar now leads to a hidden treasure chest later. For the Jump Game, grabbing the local maximum always successfully reveals whether the end is reachable.

---

## The three pillars you carry to other problems

1. **The current best state variable.** You almost always need a variable tracking the maximum boundary, the minimum cost, or the current total, like `farthest` above.
2. **A single pass.** You iterate through the data exactly once, usually an O(N) loop.
3. **The aggressive update.** Inside the loop, compare the current item against your state variable. If it improves the state, update immediately. If it breaks a rule, like `i > farthest`, fail immediately.

---

## How to identify a greedy problem

**Optimisation wording.** Minimum, maximum, fewest, most, fastest, cheapest, earliest, latest. For example "minimum number of boats".

**Local decisions accumulate into a global solution.** If you can build the answer incrementally and the current optimum does not affect future results, greedy might work.

**Future choices do not depend on past micro choices.** This is subtle. If the future state depends only on aggregate information, not on the specific order, greedy is good. We only need total time, not the order of tasks. We only need remaining capacity, not the order of packing.

**Sorting gives structure.** If sorting simplifies the decision making, greedy is often right.

**Pairing or selection problems.** Pairing people (boats), scheduling intervals, resource allocation, matching tasks to workers, coin change in specific currencies.

---

## The six common patterns

### 1. Sort plus two pointer pairing

Used when pairing items under constraints. The clue is "pair items such that the sum is at most a limit, or maximise or minimise pairs".

Examples: Boats to Save People, Assign Cookies, two sum variations at or below K.

### 2. Sort plus sweep, interval scheduling

Used for scheduling, merging and selecting tasks. The clue is intervals, deadlines, start and end times.

Sub patterns: earliest finishing time first gives the maximum non overlapping set; earliest start time first is for merging intervals; Meeting Rooms II uses a min heap for rooms.

### 3. Greedy by value ratio

Used in knapsack like problems where value per weight matters. The clue is "maximise profit subject to capacity".

Examples: fractional knapsack sorted by value over weight, job sequencing by profit and deadline.

### 4. Greedy with heaps

Used when you must always pick the best available now, repeatedly. The clue is "at every step pick the largest or smallest available".

Examples: Reorganize String, Dijkstra shortest path, min cost to connect sticks, Meeting Rooms II, CPU scheduling.

### 5. Greedy counting and frequency reduction

The clue is removing characters or items to optimise a lexicographic or numeric value.

Examples: Remove K Digits, monotonic stack for the smallest number, digit operations, character deletion problems.

### 6. Greedy partitioning and cutting

The clue is states that can be decided sequentially with adjacent influences.

Examples: Gas Station circular route, Candy distribution, Burst Balloons.

---

## The validity check, three questions

Before committing to greedy, ask all three.

**Check 1, the greedy choice property.** If I make the best local choice now, am I guaranteed not to hurt future choices? For boats, pairing heavy with light never hurts, so it is valid.

**Check 2, optimal substructure.** After making a choice, does the remaining problem look structurally identical? After pairing heavy plus light, the remaining problem is a smaller list with the same constraints, so yes.

**Check 3, no dependency cycles or backtracking needs.** If picking A before B or B before A does not matter in the long term, greedy works. If the order affects the future structure, you need DP.

---

## The template for applying it

**Step 1, identify the objective.** Minimise boats, maximise meetings, minimise cost.

**Step 2, consider the naive optimal strategy.** Ask: if time were unlimited, what decision tree would I explore? This reveals the constraints.

**Step 3, look for a sorting strategy.** Ask: if I sort by X, does the decision simplify? For interval scheduling, earliest finish.

**Step 4, try greedy candidate decisions.** Ask: what local choice seems best at each step? For boats, pair heavy plus light.

**Step 5, validate the greedy properties.** Greedy choice property, optimal substructure, no harmful future side effects. If all three pass, implement it.

---

## The formal shape

```python
S = empty solution
while not h(S):
    x = f(C)               // choose best remaining option
    if g(S, x) is valid:   // maintain feasibility
        S = S union {x}
    remove x from C
return S
```

The four pieces you must design: the candidate set, the selection rule (the greedy choice), the feasibility test, and the termination condition.

---

## Worked example: Partition Labels

Partition a string into as many parts as possible such that each character appears in at most one partition, and return the size of each partition. If a character appears again later, you cannot cut before its last occurrence.

**The core insight.** If a character appears at index `i` and its last occurrence is at `j`, then every index from `i` to `j` must be in the same partition. A partition is valid only when all characters inside it finish within it.

**The strategy.**

1. Preprocess: build a map from character to the last index where it appears.
2. Single pass scan: maintain a current partition boundary `end`, and while scanning set `end = max(end, lastIndex[currentChar])`.
3. Close the partition: when `currentIndex === end`, it is guaranteed safe to split.

**The window model.**

```python
l   -> start of the current partition
i   -> current scanning index
end -> the farthest index the current partition is forced to go

Partition = s[l ... end]
```

Size is `end - l + 1`.

**Why `l = i + 1` matters.** The partition ends at index `i`, and the next partition must start at the next unused character. If you set `l = i` the partitions overlap; if you leave `l` unchanged the sizes keep accumulating incorrectly. `l` is a bookmark, not a sliding pointer.

```python
Store last index of each character
Scan string, expanding current partition end
When index == end:
    record partition size
    move start to next index
```

**Complexity.** Time O(n), space O(1) for a bounded alphabet.

**Sanity checks.** `"EECCB"` gives `[5]`, everything overlaps into one partition. `"ababcbacadefegdehijhklij"` gives the classic multiple partitions.

> [!tip] The one line takeaway
> A partition ends only when the current index reaches the maximum last occurrence of all characters seen so far.

Problem link: [Partition Labels](https://leetcode.com/problems/partition-labels/).

---

## Worked example: Gas Station

`n` gas stations in a circle. `gas[i]` is fuel gained at station i, `cost[i]` is fuel needed to reach station i+1. Find the starting station that lets you complete the full circle, or return -1 if none exists.

**The brute force.** Try every starting station and simulate the full lap, O(n^2).

**The greedy insight.** If the total gas across the whole circle is less than the total cost, no starting point works, full stop. If total gas is at least total cost, exactly one starting point works, and you can find it in one pass.

**Why a failing point eliminates a whole range.** Walk from station 0, tracking a running tank total. The moment the tank goes negative at station `i`, no station between the current `candidateStart` and `i` (inclusive) can be the answer either. Any of them would arrive at station `i` with an equal or smaller tank than starting from `candidateStart` did, since starting later only means less gas accumulated by the time you reach `i`. So the next candidate becomes `i + 1`, and everything up to `i` is eliminated in one step, not retried individually.

```js
function canCompleteCircuit(gas, cost) {
  let totalTank = 0, currentTank = 0, candidateStart = 0;

  for (let i = 0; i < gas.length; i++) {
    const delta = gas[i] - cost[i];
    totalTank += delta;
    currentTank += delta;

    if (currentTank < 0) {
      candidateStart = i + 1;
      currentTank = 0;
    }
  }

  return totalTank >= 0 ? candidateStart : -1;
}
```

> [!tip] The one line takeaway
> A negative running tank at station `i` proves every station from the current candidate through `i` is disqualified, so the next candidate jumps straight past all of them instead of being tested one by one.

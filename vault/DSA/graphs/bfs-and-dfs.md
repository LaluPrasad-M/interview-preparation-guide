# BFS and DFS

> [!tldr]
> BFS is a ripple, so it finds the shortest path in an unweighted graph. DFS is a maze runner, so it finds all paths and explores exhaustively.

---

## Breadth first search, the ripple effect

**The metaphor.** Throwing a stone into a pond. It explores the graph in perfectly concentric, expanding ripples: level 0, then level 1, then level 2.

**Primary use case.** Shortest path in unweighted graphs. The absolute first time the ripple touches the target, it is mathematically guaranteed to be the shortest path.

**Data structure.** A queue, first in first out. You push newly discovered nodes to the back of the line.

**Memory cost.** Usually higher space complexity than DFS, because the queue must hold the entire circumference of the current ripple.

**When to use it in an interview.** If a prompt asks for minimum steps, shortest route, or fewest jumps, default to BFS immediately.

---

## Depth first search, the maze runner

**The metaphor.** A person in a physical maze. They run down a single corridor as deep as possible until they hit a dead end, then backtrack to the last intersection and try the next corridor.

**Primary use case.** Exhaustive search and backtracking. Great when you need all possible paths, want to check whether a graph has a cycle, or want to explore every permutation of a decision.

**Data structure.** A stack, last in first out, or simply the natural call stack through recursion.

**Memory cost.** Very space efficient. It only needs to store the single path it is actively exploring.

**When to use it in an interview.** If a prompt asks to find all combinations, whether a path exists without caring about its length, or to traverse the entire tree, default to DFS. It is also generally faster to type out recursively than BFS.

---

## The decision tree

```python
Does it ask MIN / SHORTEST?
        |
       YES -> BFS
        |
       NO
        |
Does it ask ALL / GENERATE?
        |
       YES -> DFS
        |
       NO
        |
Is it reachability / cycle / islands?
        |
       DFS
```

---

## The DFS structure

```python
function dfs(state) {
  if (invalid(state)) return
  if (goal(state)) record(state)

  for (choice of choices) {
    apply(choice)
    dfs(newState)
    undo(choice) // BACKTRACK
  }
}
```

Used in subsets, permutations, combinations, N Queens, Sudoku, and path enumeration.

---

## Where these show up, by category

**Trees, DFS recursion.** Traverse left and right, return something to the parent: invert binary tree, maximum depth, diameter, balanced binary tree, same tree, subtree of another tree, LCA, right side view, count good nodes, path sum, binary tree maximum path sum.

**Graphs, DFS or BFS with a mandatory visited set.** Nodes plus edges plus visited: number of connected components, clone graph, course schedule, course schedule II, pacific atlantic water flow, graph valid tree, reorder routes to make all paths lead to city zero.

**Grid and matrix, DFS flood fill.** 2D traversal with directions: number of islands, max area of island, flood fill, surrounded regions.

**Grid and graph, BFS for shortest path and levels.** Minimum steps, time or distance: rotting oranges, shortest path in binary matrix, walls and gates, word ladder, open the lock.

**Backtracking, DFS to generate all.** Make a choice, recurse, undo: subsets, subsets II, permutations, combination sum, combination sum II, generate parentheses, palindrome partitioning, letter combinations of a phone number, N Queens.

**Implicit DFS.** These do not look like DFS but internally are: accounts merge (DFS on an emails graph), evaluate division (DFS or BFS on a weighted graph), redundant connection (DFS or union find).

Roughly forty problems in total where BFS or DFS is the core skill.

---

## Worked example: number of islands

**The essence.** Count the number of connected components of land (`'1'`) in a 2D grid using DFS flood fill.

**The correct mental model.** The outer loop finds starting points of islands. DFS clears the entire connected island. Each DFS call equals exactly one island.

> When I see unvisited land, I count one island and destroy everything connected to it.

**When DFS applies here.** It is a grid problem, it counts regions or components, and there is no shortest path or distance requirement.

### Mistakes worth remembering

**Thinking loops alone are enough.** Loops move by order, but islands require connectivity. DFS exists to follow connectivity until exhaustion. DFS handles depth; loops only find starts.

**Confusion about when to count.** Counting inside DFS is wrong, and counting every land cell is wrong. Count only when DFS starts, never inside DFS.

**Misplacing the DFS calls.** Calling the four directions from the outer loop is wrong. The outer loop calls DFS once, and DFS handles all directions recursively.

**Character against number confusion.** The grid is `character[][]`, and the values are `'1'` and `'0'`, not `1` and `0`. Always compare with `===`.

**Incorrect bounds check.** Using `r > rows` instead of `r >= rows`. The valid range is `0 <= r < rows` and `0 <= c < cols`.

**Thinking a `return` is required at the end of DFS.** DFS here is procedural, not functional. `return` is only needed in the base cases.

### Correct pseudocode

```python
dfs(r, c):
    if r or c is out of bounds:
        return

    if grid[r][c] is water:
        return

    convert grid[r][c] to water   // mark visited

    dfs(r + 1, c)   // down
    dfs(r - 1, c)   // up
    dfs(r, c + 1)   // right
    dfs(r, c - 1)   // left

numIslands(grid):
    islands = 0

    for each row r:
        for each column c:
            if grid[r][c] is land:
                islands = islands + 1
                dfs(r, c)

    return islands
```

### Invariants to say out loud

After `dfs(r, c)` finishes, no land connected to `(r, c)` remains. DFS is called once per island. The outer loop never double counts, because DFS removes islands as it goes.

**Complexity.** Time O(rows times cols), because each cell is visited once. Space O(rows times cols) in the worst case, for the recursion stack.

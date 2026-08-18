# BFS Template

> [!tldr]
> One skeleton covers level order traversal, flood fill, shortest path on a grid and multi source spread. The only things that change are what counts as a neighbour and whether you need levels.

---

## The skeleton

```text
queue = [start]
visited = {start}

while queue is not empty:
    node = queue.shift()
    process(node)

    for each neighbour of node:
        if neighbour is valid and not visited:
            mark neighbour visited
            queue.push(neighbour)
```

The queue means "discovered, not processed yet".
First in first out is what gives you the distance guarantee: everything at distance `d` comes out before anything at distance `d + 1`.

---

## The two invariants to say out loud

**Every node is enqueued once and processed once.** That is what makes the whole thing linear instead of exponential.

**Mark visited when you push, never when you pop.**
Two different parents can discover the same node before either one is processed.
If you mark on pop, that node sits in the queue twice and gets processed twice, and on a big grid the queue just keeps growing.

> [!warning] Visited is mandatory on a grid
> A grid is a cyclic graph: you can walk right then left and be back where you started. Without a visited set the queue grows forever and the search may never end.

---

## Levels, when you need them

Plain BFS gives you an order. Level order gives you batches, one array per distance from the start.

At the top of each iteration the queue holds exactly the nodes of the current level, because every parent already pushed its children to the back.
So you do not detect levels, you freeze them:

```js
const result = [];
const queue = [root];

while (queue.length > 0) {
  const levelSize = queue.length;   // capture BEFORE removing anything
  const level = [];

  for (let i = 0; i < levelSize; i++) {
    const node = queue.shift();
    level.push(node.val);

    if (node.left) queue.push(node.left);
    if (node.right) queue.push(node.right);
  }

  result.push(level);
}
```

Each pass of the inner loop is a normal BFS step. The loop only groups those steps into a level.

**Distance is the number of levels processed**, not the number of nodes visited and not the number of neighbours discovered. It goes up once per level.

---

## What "start" is, by problem type

| Problem type | start |
| --- | --- |
| Tree | the root |
| Graph | the given source node |
| Grid | one cell `(row, col)` |
| Multi source | every source pushed into the queue before the loop begins |

Multi source BFS is the one people miss.
Rotting oranges and walls and gates both work by pushing every rotten orange, or every gate, into the queue up front.
The levels then measure distance from the nearest source, for free, with no extra code.

---

## Which algorithm, and when

| Algorithm | Gives the shortest path? | Condition |
| --- | --- | --- |
| BFS | yes | every edge costs the same |
| DFS | no | it finds a path, with no guarantee it is the shortest |
| Dijkstra | yes | edges have different costs |

The decision question, ahead of writing anything: do I care how far something is, or how soon it happens?
If yes, BFS. If not, DFS is usually simpler. See [[bfs-and-dfs]] for the full trigger list.

> [!tip] The mental model
> BFS is water spreading from a source. Level 1 is the cells the water reaches first, level 2 the next ring out. Each ring is one more unit of distance, so the ring the destination appears in is the shortest distance to it.

---

## Worked example: flood fill

Starting from `(sr, sc)`, recolour every cell connected to it, in four directions, that holds the same original value.

The whole problem lives in one rule, decided before the loop starts:

```text
originalValue = image[sr][sc]
only cells equal to originalValue are eligible
```

There are two honest ways to avoid processing a cell twice:

| Approach | How it blocks re-entry | Use when |
| --- | --- | --- |
| Mutation as visited | you set the cell to `newColor`, so it no longer equals `originalValue` and fails the eligibility check | mutating the input is allowed |
| Explicit visited set | a `Set` or boolean grid, marked at enqueue time | the original values are needed later, or mutation is not allowed |

Guard the no-op case first: if `originalValue === newColor`, return the image untouched, otherwise mutation as visited never blocks anything and the queue never empties.

Flood fill needs no `levelSize` and no distance tracking. It is one start expanding until nothing eligible is left, which is the same shape as counting islands in [[bfs-and-dfs]].

---

## Worked example: shortest path in a binary matrix

Move from the top left cell to the bottom right through open cells only, counting cells, moving in any of the eight directions the problem allows.

This one does need levels, because the answer is a distance.

```text
if start or end is blocked: return -1

queue = [start], visited = {start}, distance = 1

while queue is not empty:
    levelSize = queue.length
    for i in 0..levelSize - 1:
        cell = queue.shift()
        if cell is the destination: return distance
        for each of the 8 directions:
            if inside grid and open and not visited:
                mark visited
                push
    distance = distance + 1

return -1
```

The first time you reach the destination is the shortest path, which is exactly the property FIFO gives you, so you return immediately instead of continuing to search.

---

## Mistakes worth remembering

| Mistake | What it does |
| --- | --- |
| Capturing `levelSize` after removing a node | levels collapse into each other, since the count no longer matches the level |
| Processing one node but looping `levelSize` times | the same node gets handled repeatedly, the rest never do |
| A directions array written as arithmetic, for example `[1 - 1]` | it silently becomes `[0]`, and the traversal quietly explores nothing |
| Marking visited on pop instead of push | duplicates enter the queue, which wastes work and can break the distance count |
| Treating visited as optional | fine on a tree, an infinite loop on any graph with a cycle, which includes every grid |

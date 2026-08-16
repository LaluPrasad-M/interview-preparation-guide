# Tree Recursion Patterns

> [!tldr]
> If you return something computed from the children it is post order. If you pass something down to the children it is pre order. That one sentence covers most tree problems.

---

## The universal template

```text
function dfs(node) {
  if (node == null) return baseValue;

  left = dfs(node.left)
  right = dfs(node.right)

  return combine(node, left, right)
}
```

What changes between problems is only three things: when you process the node, what you return, and how you combine the results.

The two traversal families to start from are DFS, which uses a stack, and BFS, which uses a queue and gives level order traversal.

---

## Type 1: pre order, top down

Process the node before the children.

```js
function dfs(node, path) {
  if (!node) return

  path.push(node.val)
  console.log(path)

  dfs(node.left, path)
  dfs(node.right, path)

  path.pop()
}
```

**Mental model.** I know something at the parent, I pass it down. Ask: does the child depend on the parent's information? If yes, top down.

**Memory trick.** Before children means before recursion.

**Used in.** Root to leaf paths, depth calculation, carrying constraints such as min, max or sum.

**Pro tips.** Usually a void recursion or shared state. Beware of backtracking, that `path.pop()`. Avoid global state, pass arguments instead.

**Likely questions.** Root to leaf paths, max and min depth, validate BST with a range, path sum I, print tree levels with depth.

---

## Type 2: post order, bottom up

Process the node after the children. This is the most important one.

```js
function height(node) {
  if (!node) return 0

  let left = height(node.left)
  let right = height(node.right)

  return Math.max(left, right) + 1
}
```

**Mental model.** I do not know the answer until the children tell me. Ask: do I need child results to compute my result? If yes, bottom up.

**Memory trick.** Children first means calculation later.

**Used in.** Diameter, balance check, subtree aggregation, tree DP.

**Pro tips.** This is roughly 90 percent of tree problems. Think in terms of return values, combine results carefully, avoid recomputation.

**Likely questions.** Height and diameter, balanced binary tree, max path sum, count good nodes, LCA without a parent pointer, tree DP.

---

## Type 3: in order, structural

Left, node, right. Only meaningful for BSTs.

```js
let prev = -Infinity

function inorder(node) {
  if (!node) return true

  if (!inorder(node.left)) return false

  if (node.val <= prev) return false
  prev = node.val

  return inorder(node.right)
}
```

**Mental model.** A BST is a sorted array hidden inside a tree. Ask: is the problem about order, ranking, or the sorted property? If yes, in order.

**Memory trick.** BST plus sorted means in order.

**Used in.** Sorted traversal, kth smallest or largest, BST checks.

**Pro tips.** Works only for BSTs. Watch out for global state bugs. Prefer range based validation in interviews.

**Likely questions.** Kth smallest in BST, validate BST, convert BST to a sorted list, recover BST, BST iterator.

---

## Bonus type: DFS with a global answer

```js
let diameter = 0

function height(node) {
  if (!node) return 0

  let left = height(node.left)
  let right = height(node.right)

  diameter = Math.max(diameter, left + right)

  return Math.max(left, right) + 1
}
```

**Mental model.** Return something small, update something big.

Used when the answer is not rooted, meaning the path may go through any node.

---

## The master table

| Traversal | Order | Approach | Where logic lives | When to use | Typical questions | Return type | Core trick | Pitfalls |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pre order | node, left, right | top down | before recursion | passing info from parent to child | root to leaf paths, depth, path sum I, validate BST with range, print tree | void or simple | pass state as an argument, backtrack | forgetting to undo state with `pop()`, using globals |
| In order | left, node, right | structural | between recursions | order, rank or sorted logic in a BST | kth smallest, validate BST, BST iterator, recover BST | boolean or number | the tree behaves like a sorted array | using it on a non BST, global `prev` bugs |
| Post order | left, right, node | bottom up | after recursion | the current answer depends on children | height, diameter, balanced tree, LCA, max path sum | number or object | the return value is the subtree answer | wrong base case, recomputation |
| Post plus global | left, right, node | bottom up with a side effect | after recursion and in a global | the answer is not rooted at the current node | diameter, max path sum | return small, update big | return small, update big | forgetting the global update |
| DFS with state | any | mixed | depends | counting or constraints | good nodes, sum of paths | custom object | return multiple values | over engineering |

---

## The decision flow

```text
Does the parent pass info?      -> PRE-ORDER
Does the node depend on children? -> POST-ORDER
BST plus order?                 -> IN-ORDER
Answer not tied to the root?    -> POST + GLOBAL
```

---

## One line statements to steal

- Pre order: "I am passing state top down."
- Post order: "I need child results first."
- In order: "A BST gives sorted order."
- Global: "Return local, update global."

---

## Recursion tricks worth keeping

| Trick | Meaning |
| --- | --- |
| Base case first | prevents stack explosion |
| Return value equals subtree meaning | think in contracts |
| Backtracking means undoing state | mandatory in pre order |
| Never recompute | store child results |
| Talk while coding | wins interviews |

Around 90 percent of tree problems fall into: paths use pre order, heights and balances use post order, BST ranking uses in order, and global max or min uses post plus global.

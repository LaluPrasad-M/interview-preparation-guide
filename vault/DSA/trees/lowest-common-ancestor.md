# Lowest Common Ancestor: Tree vs BST

> [!tldr]
> In a plain binary tree the structure decides, so the children report upward and you go bottom up. In a BST the values decide, so the current node decides and you go top down.

---

## The mental hook

```python
No ordering?  -> wait for children -> POST-ORDER
Has ordering? -> decide immediately -> TOP-DOWN
```

---

## Side by side

| Aspect | LCA in a binary tree | LCA in a BST |
| --- | --- | --- |
| Tree property | no ordering guarantee | left is less than root is less than right |
| Core idea | children tell you where p and q exist | values tell you the direction |
| Traversal style | post order | top down, like pre order |
| Approach | bottom up | top down |
| Decision time | after recursion | before recursion |
| Subtrees explored | both, possibly the whole tree | only one path |
| Return meaning | p, q or the LCA bubbling up | the first split node |
| Uses the tree property | no | yes |
| Interview expectation | the generic solution | the optimised solution |

---

## Binary tree LCA, post order

```python
1. If root is null, return null
2. If root equals p or q, return root
3. Recurse left
4. Recurse right
5. If left and right are both non null, root is the LCA
6. Otherwise return whichever is non null
```

Why this works: you do not know where p and q are until the children report.

---

## BST LCA, top down

```python
1. If p.val < root.val AND q.val < root.val -> go left
2. If p.val > root.val AND q.val > root.val -> go right
3. Otherwise root is the LCA
```

Why this works: BST ordering lets you decide the direction instantly.

---

## Performance

| Case | Binary tree LCA | BST LCA |
| --- | --- | --- |
| Worst case | O(n) | O(h) |
| Balanced tree | O(n) | O(log n) |
| Recursion space | O(h) | O(h) |
| Early exit | no | yes |
| Pruning | none | heavy |

The algorithmic benefit of the BST approach is pruning plus an early decision.

---

## What to say

For a binary tree: "We must wait for the left and right subtree results, so this is a post order bottom up recursion."

For a BST: "The BST ordering lets us determine the LCA by value comparison, so we can prune subtrees and solve it top down in O(h)."

---

## Traps

Do not use post order for a BST without mentioning the optimisation. Do not ignore the BST property. Do not assume that "lowest" automatically means bottom up, because it does not for a BST.

The correct answer is: post order works, but a BST allows a better top down solution.

---

## The memory box

```python
Binary Tree LCA:
- No order
- Children decide
- Post-order
- O(n)

BST LCA:
- Ordered
- Values decide
- Top-down
- O(h)
```

One line: generic trees need bottom up reasoning; BSTs allow top down pruning.

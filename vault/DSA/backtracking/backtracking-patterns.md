# Backtracking

> [!tldr]
> Every backtracking solution is the same machine: enter a state, check, loop the choices, choose, recurse, undo. Four problem shapes fill that machine differently.

---

## The machine

```text
[ Enter State ]
      |
[ Check: save / stop? ]   <- logic here
      |
[ Loop choices ]          <- logic here
      |
[ Choose one ]
      |
[ Recurse with smaller input ]
      |
[ Undo choice ]           <- logic here
      |
[ Next choice ]
```

There are no other stages.

---

## Two rules to keep

**Prune operations, never prune results.** Skip work you can prove is useless rather than filtering the answer afterwards.

**Arrays are stored by reference.** If the array is being changed again after you store it in the result, store a copy instead.

---

## The universal template

Works for roughly 90 percent of cases.

```js
function backtrack(path, options) {
    // 1. Base case (goal reached)
    if (isValidSolution(path)) {
        result.push([...path]);   // or return true / count++
        return;
    }

    // 2. Try all choices from current state
    for (let choice of getChoices(options)) {

        // 3. Check constraint
        if (!isAllowed(choice, path)) continue;

        // 4. Make choice
        path.push(choice);

        // 5. Explore
        backtrack(path, updateOptions(choice, options));

        // 6. Undo choice (BACKTRACK)
        path.pop();
    }
}
```

---

## The four problem shapes

### 1. Decision, yes or no

At every step you decide to pick or not pick.

**Mental model.** For each element, include it or exclude it.

**Shape.** A binary decision tree, depth equals the number of elements. Very common for subsets style problems.

```js
function backtrack(index, path) {
  if (index === n) {
    answer.push([...path]);
    return;
  }

  // choice 1: take
  path.push(nums[index]);
  backtrack(index + 1, path);
  path.pop();

  // choice 2: skip
  backtrack(index + 1, path);
}
```

**How to identify.** The problem says include or exclude, you move the index forward every time, and order does not matter.

**Examples.** Subsets, subsets with duplicates, partition problems, some Combination Sum variants.

### 2. For loop, multiple choices

At a position you can choose one among many remaining options.

**Mental model.** At this level I can choose any of these remaining elements.

**Shape.** A for loop inside the recursion, advancing the start index with `i + 1`. This is the most common interview pattern.

```js
function backtrack(start, path) {
  if (path.length === k) {
    answer.push([...path]);
    return;
  }

  for (let i = start; i < nums.length; i++) {
    path.push(nums[i]);
    backtrack(i + 1, path);
    path.pop();
  }
}
```

**How to identify.** "Choose any", order sometimes matters and sometimes not, uses `start` or a `visited[]`.

**Examples.** Combinations, Combination Sum II, permutations with visited, letter combinations of a phone number.

### 3. Permutation, ordering

The same elements in a different order count as a different answer.

**Mental model.** You can use each element once, but order matters.

**Shape.** A `visited[]` array, looping over all elements at every level, depth equals the number of elements.

```js
function backtrack(path) {
  if (path.length === nums.length) {
    answer.push([...path]);
    return;
  }

  for (let i = 0; i < nums.length; i++) {
    if (visited[i]) continue;

    visited[i] = true;
    path.push(nums[i]);
    backtrack(path);
    path.pop();
    visited[i] = false;
  }
}
```

**How to identify.** Arrange, reorder, all possible sequences. Elements are not reused, and order matters.

**Examples.** Permutations, permutations with duplicates, string permutations.

### 4. Constraint satisfaction

You try choices, but constraints prune the tree.

**Mental model.** Try, check validity, then continue or stop.

**Shape.** A validation function, heavy pruning, usually board or grid problems.

```js
function backtrack(state) {
  if (isSolved(state)) {
    answer.push(copy(state));
    return;
  }

  for (let choice of choices) {
    if (!isValid(choice, state)) continue;

    apply(choice, state);
    backtrack(state);
    undo(choice, state);
  }
}
```

**How to identify.** Board, grid or placement problems, "no two X should conflict", a validity check is the key.

**Examples.** N Queens, Sudoku Solver, Word Search, maze paths.

---

## The one line hook

| Pattern | Ask yourself |
| --- | --- |
| Decision | pick or skip? |
| For loop | choose one among many? |
| Permutation | does order matter? |
| Constraint | do I need to validate each step? |

# Avoiding Duplicates in Backtracking

> [!tldr]
> You can use duplicates to continue a combination, but never to start the same looking combination twice. The fix belongs in the loop, not in the recursion.

---

## The concrete situation

You have two identical one rupee coins and one two rupee coin on a table:

```python
Coins on table (with positions):
[ 1a , 1b , 2 ]
```

Your task is to make combinations where order does not matter.

**The rule.** You are allowed to use both one rupee coins together. You are not allowed to start two combinations that look the same.

---

## The key moment

### Starting a combination

You are choosing the first coin, so your choices are 1a, 1b or 2.

Starting with 1a and starting with 1b are the same start, so you must pick only one of them. Pick the first 1, skip the second.

This is what `i > start` blocks.

### Continuing a combination

Your combination is already `[1]` and you are choosing the next coin. The remaining coins are `[1b, 2]`.

You are allowed to pick 1b, because this time you are continuing a combination rather than starting a new one.

### That is the entire difference

| Situation | Can pick the second 1? |
| --- | --- |
| Starting a combination | no |
| Continuing a combination | yes |

---

## Translating it into the condition

`start` means "where am I choosing from now". `i > start` means "this is not the first option at this moment".

```js
if (i > start && same number) continue;
```

which reads as: if I already saw this number at this moment, do not use it again.

> [!tip] The sentence to memorise
> You can use duplicates to continue a combination, but never to start the same looking combination twice.

---

## Loop against recursion, who does what

The for loop chooses what to try next, and the backtracking function explores what happens if you try it. They are partners, not alternatives.

| Role | Responsibility |
| --- | --- |
| for loop, the choice maker | decides which options are available at this step, runs side by side, same loop means same level |
| `backtrack()`, the explorer | takes one chosen option and goes deeper, each call is the next level |

```js
function backtrack(...) {

    for (each choice at this level) {

        choose
        backtrack(...)   // go deeper
        unchoose
    }
}
```

```python
backtrack()   <- one level
   |
   +-- for loop (choices at this level)
           |
           +-- choice 1 -> backtrack() -> deeper level
           |
           +-- choice 2 -> backtrack() -> deeper level
           |
           +-- choice 3 -> backtrack() -> deeper level
```

The loop is the width, horizontal. The recursion is the depth, vertical.

---

## Worked trace with `[1, 1, 2]`, target 4

Initial call: `backtrack([], index = 0)`.

The loop at level 0 offers `i = 0` giving 1, `i = 1` giving 1, and `i = 2` giving 2. That loop is saying: here are the possible first choices.

```python
LEVEL 0
path = []

loop:
  i=0 -> choose 1
         |
      backtrack([1], index=1)

  i=1 -> choose 1
         |
      backtrack([1], index=2)

  i=2 -> choose 2
         |
      backtrack([2], index=3)
```

Each `backtrack()` call represents one branch, has its own loop, and starts a new level.

---

## Where the duplicate bug actually lives

The bug is not in the backtracking. The bug is in the loop allowing bad choices.

```python
LEVEL 0 loop allows:
  start with 1 (index 0)
  start with 1 (index 1)  <- duplicate start
```

Both lead to identical subtrees. If the loop makes a bad choice, backtracking faithfully explores a bad branch. Backtracking is innocent.

---

## What the duplicate check actually changes

```js
if (i > index && candidates[i] === candidates[i - 1]) continue;
```

This modifies only the loop, never the recursion. Level 0 becomes:

```python
LEVEL 0
loop choices:
  i=0 -> 1  kept
  i=1 -> 1  skipped
  i=2 -> 2  kept
```

Now the recursion only explores unique branches.

---

## The final mental picture

```python
FOR LOOP  ->  controls WHICH doors exist at this level
BACKTRACK ->  walks through ONE door and explores deeper
```

If a door should not exist, because it is a duplicate start, the loop must block it. Not the backtracking.

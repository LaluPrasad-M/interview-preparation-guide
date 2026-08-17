# How to Solve a Coding Problem

> [!tldr]
> The order to work in: understand, find the invariants, try alternatives, dry run, then code. Jumping straight to code is what loses the round.

---

## The sequence

Do not rush to a solution. Take time to understand the question, break down the invariants, try alternatives, test, iterate, and finalise. Only then code.

The same habit applies to all work: coding, architecture planning, system design thinking, or debugging. While preparing and studying, always ask for the alternate solution too.

---

## The steps in order

1. **Logic.** What is the problem actually asking?
2. **Invariants.** What must stay true at every step?
3. **Mental model or pseudocode.** A working sketch you can dry run.
4. **Test case execution.** Walk your sketch through an example by hand.
5. **Edge case handling.** What breaks it?
6. **Code.** Only now.
7. **Complexity.** Always ask and question the time and space cost. This is the habit that makes you better at algorithmic basics.

---

## Invariance checking

An invariant check needs all three of these, every time:

| Bound | What to check |
| --- | --- |
| Lower bound | what happens at the smallest input, index 0, empty array |
| Upper bound | what happens at the largest input, last index, full array |
| Out of range | what happens one step past either end |

Miss one of the three and you get the off by one bug that costs you the problem.

---

## Extra habits for the pieces

- **Brute force first, then optimise.** State the brute force out loud so the interviewer knows you see the problem, then improve it.
- **Recursion and DP run in opposite directions.** A recursion usually computes from the front; the DP table for the same problem is usually filled from the opposite end.
- **Arrays are stored by reference.** If you push an array into a result and then keep mutating it, you have corrupted the result. Push a copy.
- **Prune operations, never prune results.** Skip work you can prove is useless; do not filter the answer afterwards.

---

## For system design revision

Practise drawing the architecture diagram above everything else. A design you can draw is a design you can explain.

---

## Study habits that carry over

Resist the temptation to jump ahead. Use a notebook and jot down ideas rather than holding them in your head. Revision and revisiting matter as much as learning and implementing.

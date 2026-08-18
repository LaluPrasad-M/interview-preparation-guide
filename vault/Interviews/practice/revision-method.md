# Revision Method

> [!tldr]
> Passive rereading feels productive and teaches almost nothing. Active recall, testing yourself before checking the answer, is what actually moves a topic from notes into memory.

---

## The five-step loop

| Step | Do |
| --- | --- |
| 1. Close the note | Do not look at it while you try to recall |
| 2. Recall out loud or on paper | State the idea in your own words before checking anything |
| 3. Check against the note | Compare what you said to what is written |
| 4. Mark the gap | Note the exact thing you missed, not "review again" |
| 5. Re-test the gap tomorrow | Spaced repetition on the miss, not the whole topic |

> [!tip] Retrieval practice beats rereading
> Struggling to recall something, even failing, strengthens memory more than reading the answer one more time. The effort is the point.

---

## What not to do

- Reread a note and feel like you know it. Recognising an answer is not the same as producing it.
- Highlight everything. Highlighting is decision avoidance dressed up as work.
- Review a topic the same day you learned it and nothing after. Spacing is what makes it stick.
- Make a to-do list of "review X" without writing down what specifically was wrong.

---

## The same loop, applied to code

Never reread an old solution. It gives you the feeling of knowing without the ability to produce.

1. Read the problem.
2. Close the old solution.
3. Rebuild the approach out loud.
4. Say the invariant and the complexity before writing anything.
5. Code it from scratch.

If five minutes pass and nothing comes, then open your previous submission and read it until it clicks, see [[dsa-problems]].

---

## A two day plan for the last 48 hours

Six rounds, pattern by pattern, done without looking at solutions.

| Day | Round | Cover |
| --- | --- | --- |
| 1 | fast recall, three to four hours | sliding window, prefix sum, two pointers |
| 1 | trees and graphs, three hours | diameter, balanced tree, right side view, good nodes, islands, rotting oranges, shortest path in a binary matrix |
| 1 | binary search and stack, two hours | search rotated, Koko, ship packages, daily temperatures, car fleet, valid parentheses |
| 2 | linked list and backtracking | reverse list, reorder list, remove nth, combination sum, permutations, subsets |
| 2 | DP essentials | coin change, longest increasing subsequence, unique paths, and one of target sum or partition equal subset sum |
| 2 | heap and topological sort | top k frequent, kth largest, course schedule |

Those four DP problems are chosen to give you recurrence intuition, state definition, include against exclude, and one dimensional against two dimensional, which is the whole spread in four problems.

> [!warning] What not to do in the last two days
> Do not grind random hards, do not learn obscure tricks, and do not solve twenty new mediums. Strengthen recall, revisit one problem per pattern, practise saying the approach out loud, and add only a foundational pattern you are actually missing.

The thing being tested is whether you can explain clearly, derive the solution step by step, and stay calm while debugging.
That matters more than the total number of problems solved, and it is the part revision can still change this late.

# Monotonic Stack

> [!tldr]
> A stack whose contents are deliberately kept in order, so a new element can resolve several pending ones at once. You pick the order by what you are searching for, not by what you are storing.

---

## What it means

A monotonic stack keeps elements in a chosen order:

- **Monotonically increasing:** values increase from bottom to top.
- **Monotonically decreasing:** values decrease from bottom to top.

The stack is not sorted by accident. It is sorted by design so it can answer future queries efficiently.

---

## Why they exist

They solve problems of the form "for each element, find the next element to the right or left that is greater or smaller".

Greedy and two pointers cannot do this optimally, because each index has its own future dependency and you must track several unresolved candidates at once. That is exactly what a stack is good at.

---

## The one rule

> [!tip] Decide the stack order by what you are searching for, not what you are storing
> Ask one question first: am I looking for the next greater element or the next smaller element? That single question decides everything.

| What you are finding | Stack order | Why |
| --- | --- | --- |
| next greater element | monotonically decreasing | smaller elements wait to be popped by a bigger one |
| next smaller element | monotonically increasing | bigger elements wait to be popped by a smaller one |

The memory hook is "opposites attract". Looking for greater means the stack keeps smaller values, so it is decreasing.

---

## Previous instead of next

Direction decides scan order, not stack type.

| Query | Scan |
| --- | --- |
| next element | left to right |
| previous element | right to left |

The monotonicity rule stays the same, which gives the full matrix:

| Problem asks for | Scan | Stack type |
| --- | --- | --- |
| next greater right | left to right | decreasing |
| next smaller right | left to right | increasing |
| previous greater left | right to left | decreasing |
| previous smaller left | right to left | increasing |

---

## Worked example: Daily Temperatures

For each day `i`, find the next day `j > i` where `temperatures[j] > temperatures[i]`. If none exists the answer is 0. This is next greater element to the right.

**The key insight.** When a warmer day appears, it resolves several previous colder days at once. So you should not process day `i` independently; you delay the answer until a warmer day arrives. That is the sign you need a stack.

**Values or indices?** Indices, always. You need `j - i` for the days waited, and the temperature is already reachable through the array.

**The invariant.** Temperatures at the indices in the stack are strictly decreasing, so the top is the smallest. Decreasing, because you are waiting for something greater and smaller temperatures should be resolved first.

**The two cases.** If the current temperature is not warmer than the stack top, you cannot resolve anything, so push `i`. If it is warmer, day `i` is the answer for the stack top, so pop it, compute the difference, and repeat until the stack is valid again.

```js
var dailyTemperatures = function(temperatures) {
    const n = temperatures.length;
    const result = new Array(n).fill(0);
    const stack = []; // holds indices

    for (let i = 0; i < n; i++) {

        // Resolve all previous colder days
        while (
            stack.length > 0 &&
            temperatures[i] > temperatures[stack[stack.length - 1]]
        ) {
            const prevIndex = stack.pop();
            result[prevIndex] = i - prevIndex;
        }

        // Push current day to wait for a warmer day
        stack.push(i);
    }

    return result;
};
```

**Why popping is correct.** When you pop index `prev`, you know `i` is the first warmer day for it, because any day between `prev` and `i` was not warmer, otherwise `prev` would have been popped earlier.

**Complexity.** Each index is pushed once and popped once, so 2n operations, O(n). There is a `while` inside a `for`, but there is no nested loop in reality.

---

## Why this is not greedy or two pointers

| Aspect | Greedy | Monotonic stack |
| --- | --- | --- |
| tracks a single state | yes | no |
| resolves multiple pending states | no | yes |
| next greater problems | no | yes |
| window invariant | no | no |

The problem needs you to remember unresolved indices, and only a stack does that efficiently.

Visual intuition: the stack is people standing in line waiting for a warmer day. When a hotter day comes, everyone colder gets their answer and the rest keep waiting.

---

## The greedy plus stack family

Some problems do not say "next greater" at all, and the stack is not obvious. Remove Duplicate Letters is the classic one: remove duplicates, return the smallest lexicographical result.

The trigger is not "lexicographical order". The trigger is:

> A future character can invalidate a decision I made earlier.

Suppose you have built `c b` and then see `a`. Suddenly you wonder whether you should have kept `c`, and whether you should have kept `b`. That moment is the signal.

Once you know you must undo previous choices, ask which one gets revisited first.

| Structure | Revises | Fit |
| --- | --- | --- |
| Queue | oldest decision first (FIFO) | no |
| Stack | most recent decision first (LIFO) | yes |
| Heap | smallest or largest decision | no |

In `c b` with `a` arriving, you must ask about `b` before `c`, because `b` blocks access to `c`. That is LIFO, therefore a stack.

> [!tip] The sentence to remember a month from now
> While constructing the answer, a future character can force me to undo previously selected characters, and those characters are undone from most recent to oldest. Therefore a stack is the natural structure.

The pattern, generalised:

```python
New element arrives.
I may need to revoke some previous decisions.
Revocations happen in reverse order.
=> Stack
```

---

## Worked example: Car Fleet

Count how many fleets reach the target when cars cannot overtake and faster cars must slow down.

**Key observation.** Two cars form a fleet if and only if the car behind reaches the target earlier than or at the same time as the car in front.

**Convert to a time problem.** For each car, `time = (target - position) / speed`. Catching up depends on time, not speed alone.

**Why sorting is required.** A car can only interact with cars in front of it, so process cars in position order, sorted descending by position, closest to the target first. That way fleets ahead are already decided when you process a car behind.

**What the stack holds.** Each element is one fleet's arrival time, not an individual car.

**Which order and why.** Monotonically increasing arrival times. Slower fleets, meaning larger times, come later and sit on top.

**Why nothing is ever popped.** Fleets never split or disappear. Faster cars merge into slower fleets and vanish, so you only push or ignore.

**The rule.** For each car from front to back: if `time > stackTop` it is a new fleet, so push; otherwise it catches the fleet ahead and merges, so do nothing. The stack size is the number of fleets.

```js
var carFleet = function (target, position, speed) {
    let timeTotarget = new Array(position.length).fill(0)
    for (let i = 0; i < position.length; i++) {
        timeTotarget[i] = [position[i], (target - position[i]) / speed[i]]
    }
    timeTotarget.sort((a, b) => { return b[0] - a[0] })

    let stack = []
    for (let i = 0; i < timeTotarget.length; i++) {
        if (stack.length == 0) {
            // becomes the first fleet
            stack.push(timeTotarget[i])
            continue
        }
        if (stack.length !== 0 && stack[stack.length - 1][1] > timeTotarget[i][1]) {
            // the car behind is faster and will catch up, it joins the fleet, do nothing
        }
        if (stack.length !== 0 && stack[stack.length - 1][1] < timeTotarget[i][1]) {
            // the car behind is slower and will never catch up, it creates a new fleet
            stack.push(timeTotarget[i])
        }
    }
    return stack.length
};
```

---

## The parts

| Note | Covers |
| --- | --- |
| [[monotonic-stack-problems]] | problem categorization, common traps, and the monotonic deque pattern for sliding windows |

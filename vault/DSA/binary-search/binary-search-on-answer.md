# Binary Search on the Answer

> [!tldr]
> You are not searching the input, you are searching the set of possible answers. Koko eating bananas is the canonical example.

---

## The problem, in plain English

Koko has N piles of bananas. Each pile has some bananas, for example `[3, 6, 7, 11]`.

She eats at a fixed speed of `k` bananas per hour. In one hour she can eat from only one pile. If a pile has fewer than `k` bananas she eats the whole pile and stops for that hour. She has `H` hours in total.

Find the minimum `k` so she finishes all the bananas within `H` hours.

---

## The constraints that trip people up

**One pile per hour.** She cannot split an hour across piles. Even if she eats only 2 bananas, the whole hour is used.

**Speed is constant.** The same speed every hour, and you must choose one `k`.

**You want the minimum.** Not any valid speed, the smallest one that works.

---

## Worked example

Input: `piles = [3, 6, 7, 11]`, `H = 8`.

Try `k = 3`:

| Pile | Time needed |
| --- | --- |
| 3 | 1 hour |
| 6 | 2 hours |
| 7 | 3 hours |
| 11 | 4 hours |
| Total | 10 hours, too slow |

Try `k = 4`:

| Pile | Time needed |
| --- | --- |
| 3 | 1 |
| 6 | 2 |
| 7 | 2 |
| 11 | 3 |
| Total | 8 hours, works |

Try `k = 5`: also 8 hours, so it works but it is not the minimum.

The answer is 4.

---

## The core insight

As `k` increases, the time needed decreases. Faster speed means fewer hours.

So a small `k` is impossible and a big enough `k` is possible, which is exactly the monotonic pattern:

```python
k: 1   2   3   4   5   6
   no  no  no  yes yes yes
```

---

## What are we binary searching on?

Not the piles. Not the hours. The answer itself, `k`. That is why this family is called binary search on the answer.

**Search space.** Minimum speed 1, maximum speed `max(piles)`, because eating faster than the largest pile does not help.

**The check.** For each pile, `hours = ceil(pile / k)`. Ceiling, because a pile of 7 at speed 3 needs 3 hours, not 2. Sum the hours across piles and compare with `H`.

---

## The code

```js
/**
 * @param {number[]} piles
 * @param {number} h
 * @return {number}
 */
var minEatingSpeed = function (piles, h) {
   // crucial point: understanding where binary search applies, not on the input but on the answer range
   let l = 1 // eating 1 per hour
   let r = Math.max(...piles)

   while (l <= r) {
       let mid = Math.floor((l + r) / 2)
       let hours = 0
       for (pile of piles) {
           hours += Math.ceil(pile / mid)
       }
       // do not stop when you get an answer, continue to minimise
       if (hours <= h) {
           r = mid - 1
       }
       else {
           l = mid + 1
       }
   }
   return l
};
```

The `return l` at the end is the point. When the loop exits, `l` is sitting on the first valid speed.

---

## Other problems in this family

- Ship Packages Within D Days
- Split Array Largest Sum
- Smallest Divisor Given a Threshold
- Allocate resources to minimise the maximum workload

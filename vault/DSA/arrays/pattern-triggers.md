# Pattern Triggers

> [!tldr]
> The phrase in the question tells you the pattern. This is the lookup table that turns wording into a technique before you write a line.

---

## The table

| Trigger in the wording | Pattern |
| --- | --- |
| longest or shortest subarray with a condition | variable sliding window |
| window size k | fixed sliding window |
| at most k distinct, at most k zeros | variable sliding window |
| sum equals k, divisible by k | prefix sum plus hash map |
| product less than k | sliding window, multiplicative |
| consecutive numbers | sort plus hash set |
| sorted array | two pointers |
| pair, triple or quad sums | two pointers plus sorting |
| max area, closest sum | opposite end two pointers |
| kth smallest or largest | heap or quickselect |
| merge intervals | sort plus sweep |
| next greater | monotonic stack |
| max in each window | deque |
| minimum capacity or speed | binary search on the answer |
| max subarray sum | Kadane |
| schedule, allocate, intervals | greedy |
| frequency | hash map |

---

## When it is a stack, and which kind

```python
IF nearest greater or smaller           -> monotonic stack
ELSE IF sliding window plus min or max  -> monotonic deque
ELSE IF prefix plus inequality          -> monotonic deque or stack
ELSE IF sliding window plus count       -> normal window
```

---

## Five mental models that make execution fast

**Window is a range.** Focus on what happens between `left` and `right`, not on individual elements.

**Invariants.** When shrinking a window, maintain exactly one thing: sum, product, count, frequency, or distinct count.

**Prefix plus hash.** Store prefix to frequency for sums, modulo values, and balances like plus one and minus one.

**Sort then scan.** For pairs and triples: sort, scan, skip duplicates.

**Binary search on the answer.** Convert the question into "the minimum x such that the condition holds".

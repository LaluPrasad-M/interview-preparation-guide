# Interval Problems

> [!tldr]
> Five types, and the sorting strategy is what separates them. Sort by start to merge, sort by end to select greedily, sort starts and ends separately to count overlaps.

---

## Merging intervals, the base case

The clean O(N log N) solution using the result array pattern:

```ts
type Interval = [number, number];

function merge(intervals: Interval[]): Interval[] {
  if (intervals.length <= 1) return intervals;

  // 1. Sort intervals by start time
  intervals.sort((a, b) => a[0] - b[0]);

  const merged: Interval[] = [intervals[0]];

  for (let i = 1; i < intervals.length; i++) {
    const current = intervals[i];
    const lastMerged = merged[merged.length - 1];

    // Overlap condition: current start <= last merged end
    if (current[0] <= lastMerged[1]) {
      lastMerged[1] = Math.max(lastMerged[1], current[1]);
    } else {
      merged.push(current);
    }
  }

  return merged;
}
```

---

## Type 1: merging intervals

**Goal.** Combine all overlapping intervals into non overlapping ones.

**Technique.** Sort by `start_time` ascending, iterate, and extend the end boundary when overlapping.

**Example.** Merge Intervals (LeetCode 56).

---

## Type 2: inserting into sorted intervals

**Goal.** Insert a new interval into an already sorted list of non overlapping intervals and merge where necessary.

**Technique.** A three phase linear traversal, O(N) with no sorting needed:

1. Add all intervals that end before `newInterval` starts.
2. Merge all intervals overlapping with `newInterval`.
3. Add all remaining intervals that start after `newInterval` ends.

**Example.** Insert Interval (LeetCode 57).

---

## Type 3: peak concurrency, the sweep line

**Goal.** Find the maximum number of overlapping intervals at any single point in time, such as the minimum meeting rooms or train platforms required.

**Why sort starts and ends separately?** In this problem type you do not care which specific meeting is ending. You only care about time events: a meeting started so plus one room, a meeting ended so minus one room. Creating two separate sorted arrays, `starts[]` and `ends[]`, lets two pointers sweep through time chronologically.

```ts
function minMeetingRooms(intervals: Interval[]): number {
  const starts = intervals.map(i => i[0]).sort((a, b) => a - b);
  const ends = intervals.map(i => i[1]).sort((a, b) => a - b);

  let rooms = 0;
  let endPtr = 0;

  for (let startPtr = 0; startPtr < starts.length; startPtr++) {
    if (starts[startPtr] < ends[endPtr]) {
      // A new meeting started before the earliest ending meeting finished
      rooms++;
    } else {
      // A meeting finished, free up a room
      endPtr++;
    }
  }

  return rooms;
}
```

**Examples.** Meeting Rooms II (LeetCode 253), minimum number of platforms required for a railway station.

---

## Type 4: interval intersection

**Goal.** Find the overlapping segments between two separate lists of sorted intervals.

**Technique.** Two pointer iteration over both lists. An overlap exists if `Math.max(A[i].start, B[j].start) <= Math.min(A[i].end, B[j].end)`. Increment the pointer whose interval ends earlier.

**Example.** Interval List Intersections (LeetCode 986).

---

## Type 5: non overlapping and greedy selection

**Goal.** Find the minimum number of intervals to remove so the rest are non overlapping, or find the maximum non overlapping set.

**Technique.** Sort by `end_time` ascending. Finishing an interval as early as possible leaves the maximum possible room for the remaining ones.

**Examples.** Non overlapping Intervals (LeetCode 435), Meeting Rooms I (LeetCode 252).

---

## Summary checklist

| Problem type | Sorting strategy | Key logic |
| --- | --- | --- |
| Merge Intervals | sort by `start` ascending | compare `current.start` against `prev.end` |
| Insert Interval | already sorted | three phase pass: left, merge, right |
| Meeting Rooms II | separate sorted `starts` and `ends` | two pointers tracking active overlaps |
| Interval Intersection | already sorted | `max(starts) <= min(ends)`, move the smaller end pointer |
| Min removals, greedy | sort by `end` ascending | keep the interval with the earliest end time |

---

## The sweep line, generalised

Use two pointers to generate events, then use the events to add or subtract from a running state.

Two problems built exactly on this:

1. Is carpooling possible, given car capacity, number of passengers, and pickup and dropoff distances.
2. How many platforms are required for trains, given arrival and departure times.

Reference problems: [car pooling](https://leetcode.com/problems/car-pooling/) and [divide intervals into minimum number of groups](https://leetcode.com/problems/divide-intervals-into-minimum-number-of-groups/).

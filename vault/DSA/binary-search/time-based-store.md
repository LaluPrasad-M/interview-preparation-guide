# Time Based Key Value Store

> [!tldr]
> A worked example of binary search for a floor value: the largest timestamp that is still less than or equal to the query time.

---

## The data structure

Store timestamps and values together, per key.

```text
key -> [ [timestamp, value], [timestamp, value], ... ]
```

This works because timestamps are strictly increasing, so the list is always sorted and therefore binary search friendly.

---

## What `get(key, timestamp)` is really asking

Find the largest timestamp less than or equal to the target. That is the floor, also called the rightmost valid or the last greatest at or below the target.

---

## The decision logic, which is the heart of it

Keep an invariant: `ans` holds the best valid value seen so far.

At every `mid`:

**Case 1, `arr[mid].timestamp <= target`.** This is a valid candidate, so save it in `ans` and move right to look for a later valid timestamp: `l = mid + 1`.

**Case 2, `arr[mid].timestamp > target`.** Too large, so discard the right half: `r = mid - 1`.

That is it.

---

## Implementation

```js
var TimeMap = function () {
    this.map = new Map();
};

/**
 * @param {string} key
 * @param {string} value
 * @param {number} timestamp
 * @return {void}
 */
TimeMap.prototype.set = function (key, value, timestamp) {
    if (!this.map.has(key)) {
        this.map.set(key, []);
    }
    this.map.get(key).push([timestamp, value]);
};

/**
 * @param {string} key
 * @param {number} timestamp
 * @return {string}
 */
TimeMap.prototype.get = function (key, timestamp) {
    if (!this.map.has(key)) return "";

    const arr = this.map.get(key);
    let l = 0;
    let r = arr.length - 1;
    let ans = "";

    while (l <= r) {
        let mid = Math.floor((l + r) / 2);

        if (arr[mid][0] <= timestamp) {
            // valid candidate
            ans = arr[mid][1];
            l = mid + 1; // try to find a later valid timestamp
        } else {
            r = mid - 1;
        }
    }

    return ans;
};
```

---

## Why the binary search is valid

You are finding `max(timestamp_i)` such that `timestamp_i <= target`. The condition over the array looks like:

```text
true true true false false false
```

Binary search is exactly right for that pattern.

---

## Dry run

Stored:

```text
set("foo", "bar", 1)
set("foo", "baz", 4)
set("foo", "abc", 7)
```

Query `get("foo", 5)`:

1. `mid = 1`, timestamp 4 is at or below 5, so valid, `ans = "baz"`, move right.
2. `mid = 2`, timestamp 7 is above 5, so move left.
3. Done. Return `"baz"`.

---

## Edge cases covered

| Case | Result |
| --- | --- |
| key not found | `""` |
| timestamp earlier than all | `""` |
| exact timestamp match | that value |
| timestamp between values | the previous value |
| timestamp after all | the latest value |

---

## The interview line

For each key I store values with timestamps in a sorted list and use binary search to find the largest timestamp less than or equal to the query time.

Problem link: [Time Based Key Value Store](https://leetcode.com/problems/time-based-key-value-store/description/).

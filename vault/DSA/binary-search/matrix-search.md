# Binary Search in a 2D Matrix

> [!tldr]
> Six scenarios, and the constraint you are given decides which one. Ask about the constraint before writing anything.

---

## The ten second decision map

```python
Globally sorted?        -> flatten and binary search (LC 74)
Only rows sorted?       -> binary search each row
Rows and cols sorted?   -> staircase from the top right (LC 240)
Rotated rows?           -> rotated binary search per row
Unclear constraints?    -> ask first
```

The index conversion you need for the flattened case:

```js
row = Math.floor(mid / cols)
col = mid % cols
```

---

## Scenario 1: globally sorted matrix

**Property.** Each row is sorted left to right, and the first element of a row is greater than the last element of the previous row. That means the entire matrix is globally sorted.

```js
[
  [1, 3, 5],
  [7, 9, 11],
  [13, 15, 17]
]
target = 9
```

**Memory trick.** If it looks like one long array, flatten it. Because it behaves like a flattened array, the loop runs on `l <= r`.

```js
function searchMatrix(matrix, target) {
    const rows = matrix.length;
    const cols = matrix[0].length;

    let left = 0;
    let right = rows * cols - 1;

    while (left <= right) {
        const mid = Math.floor((left + right) / 2);

        // map 1D to 2D
        const r = Math.floor(mid / cols);
        const c = mid % cols;

        if (matrix[r][c] === target) return true;
        if (matrix[r][c] < target) left = mid + 1;
        else right = mid - 1;
    }
    return false;
}
```

LeetCode 74, Search a 2D Matrix.

A useful variant, taken from the same 2D matrix note:

```javascript
var searchMatrix = function(matrix, target) {
    let row = matrix.length
    let col = matrix[0].length
    let left = 0
    let right = row * col - 1

    while(left <= right){
        let mid = Math.floor((left + right) / 2)
        let r = Math.floor(mid / col)
        let c = mid % col
        if(matrix[r][c] === target) return true
        else if(matrix[r][c] > target) right = mid - 1
        else left = mid + 1
    }
    return false
};
```

---

## Scenario 2: row wise sorted only

**Property.** Each row is sorted, with no relationship between rows.

```js
[
  [1, 4, 7],
  [2, 5, 9],
  [3, 6, 10]
]
target = 5
```

**Memory trick.** Rows do not talk to each other, so search rows separately.

```js
function searchRowSorted(matrix, target) {
    for (const row of matrix) {
        if (target < row[0] || target > row[row.length - 1]) continue;

        let l = 0, r = row.length - 1;
        while (l <= r) {
            const mid = Math.floor((l + r) / 2);
            if (row[mid] === target) return true;
            if (row[mid] < target) l = mid + 1;
            else r = mid - 1;
        }
    }
    return false;
}
```

---

## Scenario 3: rows and columns both sorted

**Property.** Rows sorted left to right, columns sorted top to bottom.

```js
[
  [1, 4, 7, 11],
  [2, 5, 8, 12],
  [3, 6, 9, 16],
  [10,13,14,17]
]
target = 14
```

**Memory trick.** The top right corner is the one cell where each move eliminates a whole row or column.

Since the matrix is only row wise and column wise sorted, start at the top right corner. If the current value is larger than the target, move left to reduce it; if smaller, move down to increase it. Each step eliminates one row or one column.

> [!warning] The loop condition is different here
> It cannot run on `l <= r`. You start at the top right corner, so the row can increase up to `matrix.length` and the column can decrease down past 0.

```js
function searchSortedRowsCols(matrix, target) {
    let r = 0;
    let c = matrix[0].length - 1;

    while (r < matrix.length && c >= 0) {
        if (matrix[r][c] === target) return true;
        if (matrix[r][c] > target) c--; // remove column
        else r++; // remove row
    }
    return false;
}
```

LeetCode 240, Search a 2D Matrix II.

---

## Scenario 4: return the position instead of a boolean

Same logic as scenario 1, different return value.

```js
function searchMatrixPosition(matrix, target) {
    const rows = matrix.length;
    const cols = matrix[0].length;

    let l = 0, r = rows * cols - 1;

    while (l <= r) {
        const mid = Math.floor((l + r) / 2);
        const row = Math.floor(mid / cols);
        const col = mid % cols;

        if (matrix[row][col] === target) return [row, col];
        if (matrix[row][col] < target) l = mid + 1;
        else r = mid - 1;
    }
    return [-1, -1];
}
```

For `target = 11` in the scenario 1 matrix, this returns `[1, 2]`.

---

## Scenario 5: rotated sorted rows

```js
[
  [4,5,6,7,0,1,2],
  [10,11,12,8,9]
]
target = 1
```

**Memory trick.** When the array is rotated, find the sorted half first.

```js
function rotatedBinarySearch(arr, target) {
    let l = 0, r = arr.length - 1;

    while (l <= r) {
        const mid = Math.floor((l + r) / 2);
        if (arr[mid] === target) return true;

        if (arr[l] <= arr[mid]) {
            if (target >= arr[l] && target < arr[mid]) r = mid - 1;
            else l = mid + 1;
        } else {
            if (target > arr[mid] && target <= arr[r]) l = mid + 1;
            else r = mid - 1;
        }
    }
    return false;
}

function searchRotatedMatrix(matrix, target) {
    for (const row of matrix) {
        if (rotatedBinarySearch(row, target)) return true;
    }
    return false;
}
```

LeetCode 33, applied per row.

---

## Scenario 6: unknown ordering

**Memory trick.** When you are not told the ordering, ask about it before writing any code.

The line to say: "Can you confirm whether rows, columns, or the entire matrix is sorted?"

# 2D Matrix Basics

> [!tldr]
> A matrix is an array of arrays. Boundaries (top, bottom, left, right) are the mental model that makes spiral, zig zag and border traversals fall out for free.

---

## What a 2D matrix is

```js
const matrix = [
  [1, 2, 3],   // row 0
  [4, 5, 6],   // row 1
  [7, 8, 9]    // row 2
];
```

Visually:

```python
Row 0:  1  2  3
Row 1:  4  5  6
Row 2:  7  8  9
```

---

## Accessing elements

The general form is `matrix[row][column]`.

```js
matrix[0][0]  // 1
matrix[0][2]  // 3
matrix[2][1]  // 8
matrix[1][2]  // 6
```

Row and column counts:

```python
Rows    = matrix.length
Columns = matrix[0].length
```

---

## Traversing the whole matrix

```js
for (let row = 0; row < matrix.length; row++) {
  for (let col = 0; col < matrix[0].length; col++) {
    console.log(matrix[row][col]);
  }
}
```

Coordinates laid out:

```python
    col0 col1 col2
row0  1    2    3
row1  4    5    6
row2  7    8    9
```

---

## Common traversal patterns

| Pattern | Output for the 3x3 above |
| --- | --- |
| Row wise, left to right | `1 2 3 / 4 5 6 / 7 8 9` |
| Column wise, top to bottom | `1 4 7 / 2 5 8 / 3 6 9` |
| Reverse row wise | `3 2 1 / 6 5 4 / 9 8 7` |
| Reverse column wise | `7 4 1 / 8 5 2 / 9 6 3` |

---

## Boundaries, the foundational idea

For this matrix:

```js
[
 [1,2,3,4],
 [5,6,7,8],
 [9,10,11,12]
]
```

You define:

```python
top    = 0   // first row
bottom = 2   // last row
left   = 0   // first column
right  = 3   // last column
```

These four boundaries represent the outer rectangle layer. Advanced traversals such as spiral, zig zag, border only and diagonals all work by controlling the area you are allowed to walk inside using `top`, `bottom`, `left` and `right`.

This is the single most important mental model for 2D problems.

---

## The four boundary walks

Before spiral, understand these four in isolation.

```js
// Top row only
for (let col = left; col <= right; col++) {
  console.log(matrix[top][col]);
}

// Right column only
for (let row = top; row <= bottom; row++) {
  console.log(matrix[row][right]);
}

// Bottom row in reverse
for (let col = right; col >= left; col--) {
  console.log(matrix[bottom][col]);
}

// Left column in reverse
for (let row = bottom; row >= top; row--) {
  console.log(matrix[row][left]);
}
```

That is exactly what spiral matrix does.

---

## Spiral order, put together

```js
/**
 * @param {number[][]} matrix
 * @return {number[]}
 */
var spiralOrder = function(matrix) {
    const result = [];
    if (!matrix.length) return result;

    let top = 0;
    let bottom = matrix.length - 1;
    let left = 0;
    let right = matrix[0].length - 1;

    while (top <= bottom && left <= right) {
        // 1. Traverse left to right
        for (let col = left; col <= right; col++) {
            result.push(matrix[top][col]);
        }
        top++;

        // 2. Traverse top to bottom
        for (let row = top; row <= bottom; row++) {
            result.push(matrix[row][right]);
        }
        right--;

        // 3. Traverse right to left, only if still valid
        if (top <= bottom) {
            for (let col = right; col >= left; col--) {
                result.push(matrix[bottom][col]);
            }
            bottom--;
        }

        // 4. Traverse bottom to top, only if still valid
        if (left <= right) {
            for (let row = bottom; row >= top; row--) {
                result.push(matrix[row][left]);
            }
            left++;
        }
    }

    return result;
};
```

---

## The sudoku box formula

To find which 3x3 box a cell belongs to:

```js
box = Math.floor(r / 3) * 3 + Math.floor(c / 3)
```

```python
0 | 1 | 2
--+---+--
3 | 4 | 5
--+---+--
6 | 7 | 8
```

---

## A trap when initialising rows

```js
const rows = new Array(9).fill(new Set()); // wrong, all rows point to the same set
```

Every row shares one object. Create them separately:

```js
const rows = new Array(9).fill(0).map(() => new Set());
```

Or equivalently:

```js
const rows = Array.from({ length: 9 }, () => new Set());
```

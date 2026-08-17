# Number Theory for Interviews, Advanced

> [!tldr]
> Advanced techniques: modulo arithmetic, prefix sums, bit manipulation, the Sieve, binary search on the answer, and specialized patterns.

Part of [[number-theory]].

---

## 6. Modulo arithmetic

```text
(a + b) % m  ===  ((a % m) + (b % m)) % m
```

```ts
const MOD = 1_000_000_007;

let ans = 0;
ans = (ans + value) % MOD;
```

Shows up in: huge numbers, counting paths, dynamic programming.

---

## 7. Prefix sum

```text
prefix[j] - prefix[i] === sum(i+1 ... j)
```

```ts
const prefix = [];
prefix[0] = nums[0];

for (let i = 1; i < nums.length; i++) {
    prefix[i] = prefix[i - 1] + nums[i];
}
```

For `nums = [1, 2, 3, 4]` the prefix array is `[1, 3, 6, 10]`.

Shows up in: subarray sum equals K, path sum III, contiguous array.

---

## 8. Bit manipulation

Odd or even:

```ts
if (n & 1) {
    console.log("Odd");
} else {
    console.log("Even");
}
```

Power of two. The trick is that `1000` and `0111` share no bits, so the AND is zero.

```ts
function isPowerOfTwo(n) {
    if (n <= 0) return false;
    return (n & (n - 1)) === 0;
}
```

Shows up in: power of two, single number.

---

## 9. Sieve of Eratosthenes

Generate every prime up to `n` at once.

```ts
function sieve(n) {
    const prime = new Array(n + 1).fill(true);

    prime[0] = false;
    prime[1] = false;

    for (let i = 2; i * i <= n; i++) {
        if (prime[i]) {
            for (let j = i * i; j <= n; j += i) {
                prime[j] = false;
            }
        }
    }

    return prime;
}

sieve(20); // prime status for 0..20
```

Shows up in: count primes.

---

## 10. Binary search on the answer

Instead of searching an index, search the answer itself. Koko eating bananas searches the eating speed.

```ts
let left = 1;
let right = maxValue;

while (left <= right) {
    const mid = Math.floor((left + right) / 2);

    if (canFinish(mid)) {
        right = mid - 1;
    } else {
        left = mid + 1;
    }
}
```

You recognise it when the answers form a monotonic pattern, `FFFFTTTT` or `TTTTFFFF`. See [[binary-search-on-answer]].

---

## 11. Negative number maths

`negative * negative = positive`, so a running maximum alone is not enough. Track `currentMax` and `currentMin` together.

Shows up in: maximum product subarray.

---

## 12. Combination formula

```text
nCr = n! / (r! * (n - r)!)
```

```ts
function factorial(n) {
    let ans = 1;

    for (let i = 2; i <= n; i++) {
        ans *= i;
    }

    return ans;
}

function nCr(n, r) {
    return factorial(n) / (factorial(r) * factorial(n - r));
}

nCr(5, 2); // 10
```

---

## Highest return if you only have 30 minutes

1. GCD
2. Prime check
3. Factors using `sqrt(n)`
4. Prefix sum
5. Binary search on the answer
6. Power of two
7. Fast power

These keep showing up, especially when an interviewer turns a normal array question into a maths optimised one.

---

## A small trick worth keeping

Splitting a number into digits:

```ts
let num = n.toString().split("").map(Number);
// 31 => [3, 1]
```

---

## The Diophantine equation

`x * a - y * b = home`, where you want to minimise `x + y`. Worth recognising when a problem is really about reaching a target with two step sizes.

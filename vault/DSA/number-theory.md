# Number Theory for Interviews

> [!tldr]
> Twelve small maths tricks that keep turning a normal array problem into a one liner. Each one is short enough to rewrite from memory.

---

## Two sums worth knowing

The first `n` odd numbers sum to `n * n`.

The first `n` even numbers sum to `n * (n + 1)`.

---

## 1. GCD, the greatest common divisor

`GCD(12, 18) = 6`, the largest number dividing both.

```ts
function gcd(a, b) {
    while (b !== 0) {
        [a, b] = [b, a % b];
    }
    return a;
}

console.log(gcd(12, 18)); // 6
```

Shows up in: rotate array with cyclic replacements, the water jug problem, fraction simplification.

---

## 2. LCM, the lowest common multiple

`LCM(12, 18) = 36`, the smallest common multiple.

The formula rides on GCD:

```text
LCM(a, b) = (a * b) / GCD(a, b)
```

```ts
function gcd(a, b) {
    while (b) {
        [a, b] = [b, a % b];
    }
    return a;
}

function lcm(a, b) {
    return (a * b) / gcd(a, b);
}

console.log(lcm(12, 18)); // 36
```

---

## 3. Prime check

Do not check up to `n`. Check up to the square root of `n`, because factors come in pairs.

```ts
function isPrime(n) {
    if (n < 2) return false;

    for (let i = 2; i * i <= n; i++) {
        if (n % i === 0) {
            return false;
        }
    }

    return true;
}

console.log(isPrime(17)); // true
console.log(isPrime(18)); // false
```

Shows up in: count primes, prime factors.

---

## 4. All factors of a number

Brute force is `for (let i = 1; i <= n; i++)`, which is O(n).

The optimal version stops at the square root, because finding `i` hands you `n / i` for free.

```ts
function getFactors(n) {
    const result = [];

    for (let i = 1; i * i <= n; i++) {
        if (n % i === 0) {
            result.push(i);

            if (i !== n / i) {
                result.push(n / i);
            }
        }
    }

    return result.sort((a, b) => a - b);
}

getFactors(36);
// [1, 2, 3, 4, 6, 9, 12, 18, 36]
```

---

## 5. Fast power

To compute `2^100`, do not multiply 100 times. Square the base and halve the exponent.

```ts
function fastPow(x, n) {
    let result = 1;

    while (n > 0) {
        if (n & 1) {
            result *= x;
        }

        x *= x;
        n >>= 1;
    }

    return result;
}

fastPow(2, 10); // 1024
```

Shows up in: `Pow(x, n)`.

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

# Number Theory for Interviews, Basics

> [!tldr]
> Five fundamental number theory techniques: GCD, LCM, primality testing, factorization, and fast exponentiation.

Part of [[number-theory]].

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

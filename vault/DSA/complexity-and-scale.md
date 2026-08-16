# Complexity and Scale Numbers

> [!tldr]
> The input size tells you the complexity the judge expects, and the powers of ten tell you the scale in a system design estimate. Both are pure memorisation, so memorise them once.

---

## The 32 bit integer bound

`2^31 - 1` is the maximum positive value of a standard 32 bit signed integer (`int` in Java, C++ and friends).

When a problem states `0 <= x <= 2^31 - 1`, it is telling you the input fits inside a normal integer variable without overflowing. Nothing more.

---

## Powers of ten, in quantities

Think in steps of three.

| Power | Value | Name |
| --- | --- | --- |
| `10^3` | 1,000 | 1 thousand (1K) |
| `10^6` | 1,000,000 | 1 million (1M) |
| `10^9` | 1,000,000,000 | 1 billion (1B) |
| `10^12` | 1,000,000,000,000 | 1 trillion (1T) |

A common slip is thinking `10^3` is 100K. It is 1K. 100K is `10^5`.

---

## Fractions of a second

Negative powers of ten, for latency estimates.

| Power | Unit |
| --- | --- |
| `10^0` | 1 second (s) |
| `10^-3` | 1 millisecond (ms) |
| `10^-6` | 1 microsecond (us) |
| `10^-9` | 1 nanosecond (ns) |

---

## The golden rule: 10^8 operations per second

Online judges give your code about one second, which means roughly 100 million basic operations.

Use the input size `N` to deduce the complexity the platform expects.

| Input size (N) | Target complexity | Typical algorithm |
| --- | --- | --- |
| `N <= 10^9` | O(1) or O(log N) | maths formula, binary search |
| `N <= 10^6` | O(N) | linear scan, hash map, two pointers |
| `N <= 10^5` | O(N log N) | sorting, divide and conquer (the most common array limit) |
| `N <= 10^4` | O(N^2) | nested loops, 2D dynamic programming |
| `N <= 500` | O(N^3) | 3D dynamic programming, matrix work |
| `N <= 20` | O(2^N) | backtracking, subsets |
| `N <= 10` | O(N!) | permutations |

---

## Bytes and powers of two

Human scale is base 10, computer storage is base 2. For system design, remember how they line up.

| Base 2 | Exact bytes | Base 10 equivalent | Unit |
| --- | --- | --- | --- |
| `2^10` | 1,024 | ~`10^3` | 1 KB |
| `2^20` | 1,048,576 | ~`10^6` | 1 MB |
| `2^30` | 1,073,741,824 | ~`10^9` | 1 GB |
| `2^40` | 1,099,511,627,776 | ~`10^12` | 1 TB |

---

## Back of the envelope shortcuts

- **Seconds in a day:** 86,400. Round to `10^5` for fast mental maths.
- **Traffic shorthand:** 100,000 requests per day is roughly 1 request per second, because 100k divided by 86.4k is about 1.
- **Monthly shorthand:** 2.5 million requests per month is roughly 1 request per second.

Data type sizes worth knowing:

| Thing | Size |
| --- | --- |
| 1 ASCII character | 1 byte |
| 1 32 bit integer | 4 bytes |
| 1 UUID | 16 bytes |

> [!tip] The one you will actually use
> `10^5` seconds per day turns "requests per day" into "requests per second" by moving the decimal point five places. Everything else follows from that.

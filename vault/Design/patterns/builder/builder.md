# Builder Pattern

> [!tldr]
> The builder is a temporary bucket. The real class never exists in a half built state, because it is created in one atomic step at the end.

---

## The problem

An object requires many constructor parameters, some optional, leading to the messy `new Order("Rahul", null, null, true, "123 Main st")` anti pattern.

---

## The solution

Construct complex objects step by step using method chaining, returning `this`.

---

---

## The parts

| Note | Covers |
| --- | --- |
| [[builder-pattern-foundation]] | problem, solution, theory, simple and separate builder examples |
| [[builder-nested-worked-example]] | production-ready nested builder with machine coding harness |

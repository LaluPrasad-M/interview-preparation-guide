# Singleton Pattern

> [!tldr]
> Hide the constructor, expose a static `getInstance()`. In JavaScript and TypeScript, an ES module export is usually the better answer.

---

## The problem

You need exactly one instance of a class across the entire application.

**When to use.** Database connections, loggers, config managers.

---

## The parts

| Note | Covers |
| --- | --- |
| [[singleton-pattern-and-examples]] | lazy initialization, eager initialization, ES module singleton, cache manager, counter |
| [[singleton-advanced-examples]] | connection pool with test suite, pros and cons |

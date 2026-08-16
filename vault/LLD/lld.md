# Low Level Design

> [!tldr]
> Nouns become entities, verbs become services, and change points become abstractions. Patterns come last, not first.

---

## Method

| Note | Covers |
| --- | --- |
| [[six-step-framework]] | the sequential model for any LLD interview |
| [[abstraction-and-dependency-injection]] | how abstraction, DI and polymorphism connect |
| [[inheritance-vs-composition]] | the fragile base class, the gorilla and banana, and the full interview answer |

---

## Patterns

| Note | Solves |
| --- | --- |
| [[strategy]] | massive `if/else` logic dictating behaviour |
| [[factory]] | scattered or conditional object instantiation |
| [[observer]] | many unrelated systems reacting to one change |
| [[builder]] | too many constructor parameters, some optional |
| [[singleton]] | exactly one instance across the application |
| [[patterns-js-vs-ts]] | each pattern in both languages, the Node module cache pitfall, three interview answers |

---

## Practice

| Note | Covers |
| --- | --- |
| [[checkout-worked-example]] | four patterns wired together, plus the pattern mapping table |
| [[ride-booking-worked-example]] | the six steps end to end, the request trace, the composition root |
| [[machine-coding-list]] | seven levels of problems with their mental triggers |

---

## Related

The OOP foundations are in [[four-pillars]] and [[solid]].

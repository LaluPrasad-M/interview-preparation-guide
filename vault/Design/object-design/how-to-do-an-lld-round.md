# The 6 Step LLD Framework

> [!tldr]
> The sequential mental model for any LLD interview. Do not jump straight into classes or patterns.

---

## Step 1: nouns become entities

**Ask.** What are the core business objects?

**Goal.** Define state, identity and ownership.

**Output.** Classes, enums, models.

For a ride hailing app: `Ride`, `Driver`, `Rider`, `Vehicle`, `Location`.

> [!warning] The gotcha
> Entities represent data and state, not workflows. Avoid classes like `RideManager` in this step.

---

## Step 2: verbs become services

**Ask.** What actions happen in the system?

**Goal.** Separate data from orchestration.

**Output.** Services, workflows. For example `requestRide()`, `assignDriver()`, `cancelRide()`.

> [!tip] The golden rule
> Entities hold state. Services hold workflows.

---

## Step 3: define relationships and state machines

**Ask.** How are entities connected? What states exist?

**Relationships.** Prefer composition and aggregation, the has-a relationship, over inheritance, the is-a relationship. See [[inheritance-vs-composition]].

**State machine.** Define enums, transitions and validations, for example `REQUESTED -> ASSIGNED -> STARTED -> COMPLETED`.

### The six relationship types

Ask which of these applies, and the answer tells you the construct.

| Question | Becomes |
| --- | --- |
| IS-A? | inheritance |
| HAS-A? | composition or aggregation |
| USES-A? | dependency |
| IMPLEMENTS-A? | an interface |
| OWNS-A? | composition |
| REFERENCES-A? | aggregation or association |

### What each thing you identify becomes

| Thing identified | Usually becomes |
| --- | --- |
| Noun | entity or class |
| Action or verb | method or service |
| Lifecycle | state or enum |
| Relationship | association or composition |
| Variable business rule | strategy |
| Sequential process | workflow |
| External dependency | adapter or gateway |
| Object creation complexity | factory |

---

## Step 4: apply single responsibility

**Ask.** Who owns what responsibility? Avoid god classes.

| Layer | Owns |
| --- | --- |
| Entity | local state rules and invariants |
| Service | workflow and business logic |
| Repository | DB access and persistence |
| Strategy | replaceable algorithms |

---

## Step 5: identify change points and add abstractions

**Ask.** What will likely change independently later?

**Goal.** Extensibility and the open closed principle.

Typical change points are pricing, matching algorithms, payment methods and notifications.

**Action.** Introduce interfaces and strategy patterns here, to avoid giant if else chains.

---

## Step 6: wire dependencies cleanly

**Ask.** How do classes collaborate?

**Flow.** Controller, then service, then repository.

**Goal.** Control the dependency direction via dependency injection. See [[abstraction-and-dependency-injection]].

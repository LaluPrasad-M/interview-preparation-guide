# Prep Checklist

> [!tldr]
> Seven blocks with priorities. P0 items are the ones you cannot afford to be shaky on.

---

## What the round actually covers

Method overloading and overriding. The four pillars of OOP. Design patterns and principles. Node.js internals, plus simple Node.js questions. A small program on sorting or searching. TDD and BDD. SQL queries. Questions on everything in the resume.

Scenario based questions, for example: what would you do if the application is crashing and you receive a P1 incident? Database downtimes, authentication failures, infrastructure issues.

Support related questions, where the most important thing is hands on experience with production issues. Monitoring tools experience, including Prometheus and Grafana. Knowledge of ticketing systems and incident management.

---

## Block 1: object oriented programming and design, P0

- The four pillars, in a JS and TS context with compiler and prototype deep dives. See [[four-pillars]] and [[js-vs-ts-compilation]].
- Method overloading against overriding. See [[overloading-vs-overriding]].
- SOLID principles. See [[solid]].
- Design patterns: singleton, factory, strategy, observer. See [[lld]].

---

## Block 2: incident management and support, P0

- Root cause analysis process and P1 incidents
- App crashes and memory leaks in Node.js
- Database downtimes and infrastructure issues
- Monitoring tools
- Ticketing workflows and the incident management lifecycle

See [[categories]] for the ten incident buckets.

---

## Block 3: resume defence and incident stories, P0

- A security or auth failure story, covering mTLS and JWE/JWS cryptography
- A performance or database downtime story, covering search index optimisation
- An infrastructure issue story, covering Kafka consumers and high volume event processing
- A deep dive on an ingestion framework you built

---

## Block 4: Node.js deep dive, P0

- The event loop and asynchronous I/O. See [[event-loop]].
- Streams and buffers
- Error handling, promises and async/await. See [[promises]].

---

## Block 5: unit testing, P1

- TDD and BDD concepts
- Mocha and Chai syntax: `describe`, `it`, `expect`, `should`

---

## Block 6: data structures, algorithms and databases, P0

- Sorting and searching algorithms, especially binary search and merge sort. See [[binary-search-patterns]].
- SQL queries: joins, indexing and query optimisation. See [[joins]] and [[study-roadmap]].

---

## Block 7: high level and low level design, P1 and P2

- Microservices scalability and HLD. See [[system-design]].
- Generic backend service LLD. See [[six-step-framework]].

# Worked Example: Ride Booking

> [!tldr]
> This applies the six step framework end to end. The interesting decisions are the ones we deliberately did not make: no `User` base class, no `Vehicle` hierarchy.

Follow [[how-to-do-an-lld-round]] alongside this. Every piece of code below maps to one of its steps.

---

## The layering

```text
                HTTP REQUEST
                      |
                      v
               +------------+
               | Controller |
               +------------+
                      |
                      v
               +------------+
               |  Service   |
               +------------+
                /     |      \
               v      v       v
      +----------+ +----------+ +------------+
      | Entities | | Strategy | | Repository |
      +----------+ +----------+ +------------+
                                       |
                                       v
                                 +----------+
                                 | Database |
                                 +----------+
```

---

## The parts

| Note | Covers |
| --- | --- |
| [[ride-booking-entities-and-states]] | entities, state enums, state machine |
| [[ride-booking-strategies-and-services]] | repositories, strategies, service orchestration |
| [[ride-booking-assembly]] | wiring, end-to-end trace, dependency injection |

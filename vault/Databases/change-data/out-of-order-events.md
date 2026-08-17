# Handling Out of Order Events in the Database

> [!tldr]
> Let the database reject stale writes. A comparison in the `WHERE` clause is cheaper and safer than trying to enforce ordering upstream.

---

## The timestamp logic, simplified

Two events happen for contact ID 1:

- **Event A.** Name changed to "John", at 10:00 AM.
- **Event B.** Name changed to "Johnny", at 10:05 AM.

Because the internet is chaotic, event B arrives at your server first.

1. Your database saves "Johnny" and sets `last_updated` to 10:05 AM.
2. The delayed event A arrives.
3. The query checks: is the incoming timestamp (10:00) greater than the saved timestamp (10:05)?
4. It is not, so the database rejects event A entirely. "Johnny" is safely preserved.

---

## Other database ways to handle it

**Version numbers, optimistic locking.** Every event has a version, `v1`, `v2`, `v3`. The rule is simply `UPDATE ... WHERE incoming_version > current_version`.

**State machines.** Useful for e-commerce. You have states `CREATED -> PAID -> SHIPPED`. If a `SHIPPED` webhook arrives before the `PAID` webhook, your code checks the strict hierarchy. It allows the DB to jump to `SHIPPED`, and when the `PAID` event finally arrives it is ignored, because `SHIPPED` is a higher terminal state.

---

## The related read side guarantee

The read side equivalent is monotonic reads: if a user refreshes a page and sees v2 of their data, the routing guarantees they will never subsequently be sent to a lagging replica that shows them v1. See [[replication-lag]].

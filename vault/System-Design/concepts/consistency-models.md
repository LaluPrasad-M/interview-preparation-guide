# Consistency Models

> [!tldr]
> Ninety five percent of backend interviews revolve around four of these. Classify your system's data into the four buckets and you are already ahead.

The replication techniques that deliver these guarantees are in [[replication-lag]]. This note is the taxonomy.

---

## 1. Strong consistency

**The promise.** Once a write succeeds, every future read sees that write.

**The example.** A bank balance. You transfer money, immediately check the balance, and you must see the updated figure, not the old one.

Used for payments, bank balances, inventory reservations, seat booking.

---

## 2. Read your writes

**The promise.** The user who performed the write will see their own write. Other users may not see it immediately.

**The example.** A profile picture update. You upload a new picture and refresh, and you should see the new one even if other users still see the old one.

Used for user profile updates, preferences, settings.

---

## 3. Monotonic reads

**The promise.** Once you have seen newer data, you never see older data again.

**The example.** Food delivery tracking.

```text
Good:                Bad:
Preparing            Delivered
   |                    |
Picked Up            Preparing
   |
Delivered
```

Used for order tracking, shipment tracking, payment status tracking.

---

## 4. Eventual consistency

**The promise.** All replicas will eventually converge. No guarantee about when.

**The example.** Likes on a post. You like it, some users see 100 likes and others see 101 for a few seconds, and eventually everyone sees 101.

Used for likes, ratings, reviews, analytics, recommendations.

---

## 5. Causal consistency

This one occasionally appears in senior interviews.

**The promise.** Cause must appear before effect.

**The example.** A user posts "I got promoted", then comments "Thanks everyone!". You should not see the comment before the post, because the comment depends on the post.

Used for social media, chat systems, collaborative systems.

---

## 6. Session consistency

**The promise.** During a user session, behaviour remains consistent. Think of it as read your writes plus monotonic reads combined.

**The example.** A shopping cart. You add an item, and you should not lose it on the next refresh.

---

## What actually gets asked

| Consistency model | Example |
| --- | --- |
| Strong consistency | payments, inventory |
| Read your writes | profile updates |
| Monotonic reads | order tracking |
| Eventual consistency | ratings, likes |

---

## The cheat sheet

Whenever you are designing a system, ask these four questions in order.

| Question | Answer | Examples |
| --- | --- | --- |
| Can stale data cause financial loss? | strong consistency | payments, inventory, seat booking |
| Should the user immediately see their own update? | read your writes | profile, preferences |
| Should status only move forward? | monotonic reads | order status, delivery tracking |
| Can data be slightly stale? | eventual consistency | reviews, ratings, likes, analytics |

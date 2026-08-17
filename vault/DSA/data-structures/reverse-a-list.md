# Reversing a Linked List

> [!tldr]
> Four steps in a fixed order. Save the future before you burn the bridge behind you.

---

## The four step shuffle

Imagine `previous` and `current` are two physical fingers pointing at the nodes.

1. **Save the future.** `next = current.next`. You must remember where you are going before you burn the bridge behind you.
2. **Reverse the pointer.** `current.next = previous`. The bridge is now burned and the current node points backwards.
3. **Slide `previous` forward.** `previous = current`. The trailing finger moves up to the node just finished.
4. **Slide `current` forward.** `current = next`. The active finger moves up to the future node saved in step 1.

Get the order wrong and you lose the rest of the list, which is the whole difficulty of the problem.

---

## The three pointers, named

`prev`, `curr`, `next`. Save `next`, flip `curr.next` to `prev`, then step them all forward.

That phrasing is the mental trigger to keep: **the 3 pointers**.

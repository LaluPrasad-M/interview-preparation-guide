# Amortised Analysis

> [!tldr]
> Averaging the cost of one expensive step across the many cheap steps around it, so the number you quote describes the whole run instead of its worst single moment.

Rent works the same way. You pay it once a month, but you do not say that living costs a fortune on the 1st and nothing for the rest of the month. You spread the one big payment across all the days it covers.

> [!example]- Appending to a dynamic array
> An array has room for 4 items and all 4 slots are full.
> Adding a 5th item allocates a new array of 8 slots and copies the 4 old items across, which is slow.
> But that one copy buys you 4 more instant appends before the next resize.
> Every doubling copies more items, and every doubling also buys proportionally more free appends, so the cost per append averages out flat.
> Ten million appends cost about ten million steps in total, so each append is O(1) amortised even though one of them was O(n).

Amortised is not the same as average case, and the difference gets asked about.

| Term | What it averages over | Example |
| --- | --- | --- |
| Worst case | the single most expensive operation | one array resize is O(n) |
| Average case | the spread of possible inputs | quicksort is O(n log n) on a random pivot |
| Amortised | a sequence of operations on the same structure | n appends cost O(n) in total, so O(1) each |

The same trick shows up well outside data structures. Batching a hundred writes behind one `fsync` amortises that one slow disk flush across all hundred, and a single bulk insert amortises the index bookkeeping across every document in the batch.

**Shows up in:** [[write-path-basics]], [[websales-lld]].

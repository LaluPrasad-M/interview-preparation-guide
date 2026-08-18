# Skip List

> [!tldr]
> A sorted linked list with extra layers of shortcut pointers above it, so search, insert and delete all run in logarithmic time without any of the rebalancing a tree needs.

The bottom layer holds every element in order. Each layer above holds a random sample of the one below it, roughly half, so higher layers skip further per hop. You start at the top left, move right until the next value would overshoot, then drop down a layer and repeat.

```text
level 2:  1 --------------------------> 9
level 1:  1 --------> 5 --------------> 9
level 0:  1 -> 3 -> 5 -> 7 -> 8 -> 9 -> 12      searching for 8: 1, then 5, then 7, then 8
```

That is a fast train stopping at major stations, then a local one for the last stretch, instead of walking the whole line.

| | Skip list | Balanced tree |
| --- | --- | --- |
| Search, insert, delete | O(log n) on average | O(log n) guaranteed |
| Staying balanced | randomness on insert, no fixing needed | rotations after writes |
| Code to get right | short | considerably longer |
| Range and rank queries | easy, the bottom layer is already a sorted list | doable, less direct |

Redis sorted sets are a hash table plus a skip list, and the pairing is the interesting part. The hash table gives O(1) score lookup by member, and the skip list keeps everything ordered so `ZRANGE` and `ZRANK` stay fast. That combination is exactly what a leaderboard needs: look up one player instantly, and still ask for ranks 1 to 10.

**Shows up in:** [[realtime-leaderboard]], [[machine-coding]].

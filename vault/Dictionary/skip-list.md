# Skip List

> [!tldr]
> A linked list with extra layers of shortcut pointers, so search, insert and delete all run in logarithmic time without the rebalancing a tree needs.

Each layer skips over more elements than the one below it, so a search drops down a layer whenever it overshoots the target.

Redis sorted sets are a hash table plus a skip list: the hash table gives constant time score lookup by member, the skip list keeps everything ranked for fast range and rank queries.

**Shows up in:** [[realtime-leaderboard]], [[machine-coding]].

# Last Write Wins (LWW)

> [!tldr]
> When two places write the same record at nearly the same time, the one with the later timestamp overwrites the other and the loser is gone. No error, no merge, no record that it happened.

It is the default conflict resolution in DynamoDB and Cassandra, and it is popular because it needs no coordination: each replica can decide the winner on its own just by comparing timestamps.

> [!example]- Why clock drift makes this dangerous
> ```text
> 10:00:05.000  Mumbai region    user adds a laptop to the cart
> 10:00:07.000  Frankfurt region user adds a phone to the cart
> ```
> Frankfurt happened later, so the phone should win. But Frankfurt's server clock is running 4 seconds behind, so it stamps its write `10:00:03`. Mumbai's stamp of `10:00:05` looks later, so the laptop wins and the phone silently disappears from the cart.
> The write that survived is not the write that happened last. It is the write from the machine with the more optimistic clock.

| Approach | What happens to a conflict | Cost |
| --- | --- | --- |
| Last write wins | later timestamp survives, the other is dropped | data loss, and it depends on clock accuracy |
| Conflict-free Replicated Data Type (CRDT) | both writes merge by rules, so a cart keeps both items | real complexity, and merge rules per data type |
| Vector clocks | conflict is detected and handed back to the application | you must write the resolution logic yourself |

> [!tip] Ask what the lost write was
> Losing one of two nearly simultaneous profile picture updates is fine. Losing an item from a shopping cart or a line from an audit log is not. Last write wins is a legitimate choice, but it should be a choice, not a default you inherited.

**Shows up in:** [[multi-region-cart]], [[sharding-and-scale]], [[nfr-decision-table]].

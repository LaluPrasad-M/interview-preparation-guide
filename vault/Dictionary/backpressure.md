# Backpressure

> [!tldr]
> The slow side of a pipe tells the fast side to hold off, so the fast side cannot bury it in work that piles up in memory.

Picture pouring water into a funnel. If you pour faster than the funnel drains, the funnel overflows. Backpressure is the funnel telling your hand to stop pouring.

The fast side is usually reading, and the slow side is usually writing to disk, network or another service. Without a signal between them, the extra data has to sit somewhere, and that somewhere is memory until the process dies.

> [!example]- Copying a 10 GB file in Node
> The disk read gives you 100 MB per second and the network upload only takes 10 MB per second.
> With no backpressure, 90 MB of unsent data piles up in memory every second, so the process is out of memory in under a minute.
>
> ```js
> readable.on('data', (chunk) => {
>   const ok = writable.write(chunk);
>   if (!ok) readable.pause();               // buffer is full, stop reading
> });
> writable.on('drain', () => readable.resume());  // it caught up, carry on
> ```
>
> `readable.pipe(writable)` does exactly this for you, which is why piping a huge file stays at flat memory while a manual loop does not.

The same signal exists at every layer, only the wording changes.

| Layer | Fast side | Slow side | The signal |
| --- | --- | --- | --- |
| Node stream | file read | disk or socket write | `write()` returns `false` |
| Kafka | producer | consumer | consumer lag grows |
| Public API | callers | your server | `429 Too Many Requests` |
| Bounded queue | producer | worker pool | the queue refuses the item |

> [!tip] Rejecting work is a feature
> A system with no backpressure does not stay fast under overload, it accepts everything and then dies all at once. Saying no early is how you fail predictably instead of catastrophically.

**Shows up in:** [[timeouts-and-circuit-breakers]], [[express-internals]], [[event-loop-lag]], [[scaling-stages]], [[nfr-decision-table]], [[notification-delivery]], [[what-breaks-in-production]], [[voice-orchestrator]].

# Node Profiling

> [!tldr]
> Four separate tools for four separate questions: is memory growing, is the event loop lagging, where does CPU time go, and when does GC pause the world. Reach for the one that matches the symptom, not all four at once.

---

## The built-in numbers

| API | Tells you |
| --- | --- |
| `process.memoryUsage()` | heap used, heap total, external, and RSS |
| `process.cpuUsage()` | user and system CPU time consumed, in microseconds |
| `perf_hooks.performance.now()` | high resolution timestamps for measuring a span of code |
| `perf_hooks.monitorEventLoopDelay()` | a histogram of how long the event loop takes to get back around |

> [!warning] heapUsed is not the whole picture
> `heapUsed` is only the V8 JavaScript heap. RSS (resident set size) is the total memory the process holds, including buffers, native add-ons and everything outside V8's heap. A process can have flat `heapUsed` and climbing RSS at the same time, usually from buffers or native modules, and only RSS will show it.

---

## Event loop lag, measured directly

```js
const { monitorEventLoopDelay } = require('perf_hooks');

const histogram = monitorEventLoopDelay({ resolution: 20 });
histogram.enable();

setInterval(() => {
  console.log('p50', histogram.percentile(50));
  console.log('p99', histogram.percentile(99));
  histogram.reset();
}, 5000);
```

This measures actual delay, not CPU usage. A busy loop and an idle-but-starved loop look identical in `cpuUsage()`, but only one of them shows up as lag here.

Numbers to judge the output against:

| Reading | Means |
| --- | --- |
| mean 2 ms, max 10 ms | healthy, the loop is keeping up |
| mean above 100 ms | something is blocking often enough to hurt every request |
| mean 400 ms, max 2500 ms | the loop is blocked, and users are seeing seconds of latency |

> [!tip] eventLoopUtilization for the "is it actually busy" question
> `performance.eventLoopUtilization()` returns the fraction of time the loop spent doing work versus waiting in poll. Low utilisation with high lag numbers usually points at something external, like a slow downstream call holding callbacks pending, rather than CPU-bound code on your own thread.

---

## CPU profiling and flamegraphs

```bash
node --cpu-prof --cpu-prof-dir=./profiles server.js
```

This produces a `.cpuprofile` file, loadable in Chrome DevTools' Performance tab or via `speedscope`, as a flamegraph. Width is time spent, not call count, so the wide frames are where CPU time actually went, regardless of how many times a function was called.

---

## Heap snapshots

```bash
node --inspect server.js
```

Then connect Chrome DevTools and take a heap snapshot.

| Term | Means |
| --- | --- |
| Shallow size | memory the object itself owns, not what it references |
| Retained size | memory freed if this object were garbage collected, including everything it alone keeps alive |

A large shallow size points at one big object. A large retained size with a small shallow size usually means one small object is the only thing keeping a large subtree alive, for example a stale closure holding a reference to something huge.

---

## GC tracing

```bash
node --trace-gc server.js
```

| GC type | Also called | Cost | Triggers on |
| --- | --- | --- | --- |
| Minor GC | Scavenge | fast, sub-millisecond usually | the young generation filling up |
| Major GC | Mark-Sweep-Compact | slow, can be tens of milliseconds | the old generation filling up, or under memory pressure |

> [!tip] A Major GC pause is a common, invisible P99 cause
> A Mark-Sweep-Compact pause stops JavaScript execution for its duration. It will not show up in application logs as an error, only as a latency spike that correlates with nothing in your own code. If P99 latency spikes line up with GC trace timestamps, that is the answer, not a downstream dependency.

See [[incident-triage]] for reading this alongside CPU and event loop lag during an actual spike.

---

## The tools people actually run in production

The built-ins above answer one question each. These wrap them up for real services.

| Tool | What you use it for |
| --- | --- |
| `clinic doctor` | first pass on a running app, tells you whether the problem is CPU, GC, I/O or event loop lag |
| `clinic flame` | flamegraph of where CPU time went |
| `clinic bubbleprof` | async bottlenecks, slow promise chains, which is the one to reach for when P99 exploded and CPU is fine |
| `0x` | a lighter flamegraph, one command, `npx 0x app.js` |
| `pm2 monit` | live CPU, memory, restarts and event loop in a terminal, when you have shell access and no dashboard |
| OpenTelemetry | traces across services, showing which hop the latency came from |
| Datadog or New Relic | the same idea as a paid product, with slow transactions, slow queries and external calls already broken out |

> [!tip] Which one for which symptom
> Latency up and CPU up, use a flamegraph. Latency up and CPU flat, use traces, since the time is being spent waiting on something outside this process. See [[where-to-look-by-component]] for the signal to component lookup.

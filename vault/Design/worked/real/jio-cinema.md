# Jio Cinema at Peak Traffic

> [!tldr]
> Streaming an IPL match: load that is known in advance, enormous, and unforgiving. Everything here answers one question, what do you do when you cannot afford to be slow for a minute.

---

## Decide what actually matters

Features get ranked before the match, and that ranking drives every decision during it.

| Priority | Features |
| --- | --- |
| **P0**, must never break | the match video, the ads |
| **P1 and P2**, allowed to degrade | comments section, page animations, anything not part of streaming |

> [!tip] The most useful habit in the whole case study
> Once everyone has agreed that comments are P2, you are allowed to switch them off to protect the video, and nobody argues about it during the incident.

---

## Frontend

| When | What is in place |
| --- | --- |
| **Before the match** | load testing, and [[canary-release]] to find a build known stable before traffic arrives |
| **During the match** | feature flags ready so anything can be turned off without a deploy, external monitoring through Datadog and Sentry, retries using [[exponential-backoff]] |

> [!warning] Turn down the alert noise
> Alerting is tuned so only high priority alerts fire. A wall of P1 and P2 noise means nobody sees the real problem.

---

## Snapshots, or how to fail without users noticing

Before the match, the system calls the APIs that provide match details, lineups and player stats, and stores those responses.

```json
{
  "match_id": 12345,
  "teams": ["Team A", "Team B"],
  "status": "upcoming",
  "start_time": "2025-02-26T18:00:00Z",
  "venue": "Stadium XYZ"
}
```

When one of those APIs dies mid match, the system enters **panic mode** and serves the snapshot instead of an error. It is slightly stale, but the user sees teams, venue and start time rather than a blank screen. Live data resumes when the API recovers.

> [!tip] Generalise it
> For data that changes rarely, a stale answer beats an error every time.

---

## Kafka under pressure

| Situation | Move |
| --- | --- |
| Producer cannot reach Kafka | write messages to local storage, send them later, drop nothing |
| Kafka is flooded | switch off consumers doing low priority work so the cluster can finish high priority jobs |

Partition counts get chosen by comparing how fast producers write to how fast consumers read.

---

## Aman's notes from the talk

- **Feature flags**, served by a config service that decides per app version, geography and platform.
- **Metrics** watched closely throughout.
- **Retries** with exponential backoff, and a cap. Three retries from enough clients can take the system down by itself.
- **Autoscaling does not help during the game.** New machines take too long to start. Size the fleet ahead of time using back of the envelope maths on expected API calls, database calls and latency.
- **Panic modes everywhere.** Always have plan B, C and D.
- **Handle sudden spikes**, the ones shaped like a hockey stick.
- **Never scale down mid match.** Scale down afterwards, gradually, one step at a time.
- **Multiple [[cdn|CDNs]]**, with a Multi CDN Optimizer service that watches how hot each CDN is and distributes load between them. Separate handling for video, API and image traffic.
- **Heavy use of Kafka** for async work.

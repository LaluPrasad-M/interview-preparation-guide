# Capacity Estimation

> [!tldr]
> The interviewer cares far more about what breaks first than about the exact [[qps|QPS]]. Capacity planning exists to find the bottleneck, not to produce a number.

---

## Why do it at all

Before discussing Kafka, Redis, sharding or microservices, answer one question: how big is the system?

Architecture depends on scale. 100 QPS is not 10,000 QPS. 1 TB is not 1 PB.

---

## Numbers to memorise

**Time.** A day is 86,400 seconds. For back of the envelope work, round to 10^5 seconds per day.

| Daily requests | Roughly |
| --- | --- |
| 1 million | 12 QPS |
| 10 million | 120 QPS |
| 100 million | 1,200 QPS |
| 1 billion | 12,000 QPS |

**Storage.** Interview calculations use powers of ten. 1 KB is 10^3 bytes, 1 MB is 10^6, 1 GB is 10^9, 1 TB is 10^12, 1 PB is 10^15.

**Data sizes.** A single character is 1 byte. A 64 bit integer ID is 8 bytes, and a UUID is 16 bytes, since it is 128 bits. A short text message is 100 to 200 bytes. An image is 100 KB to 2 MB. A video is 50 MB to several GB.

> [!warning] The source has this wrong
> The revision doc lists "an ID, UUID or 64 bit integer" as 8 bytes. A UUID is 16 bytes. [[complexity-and-scale]] has the correct figure, and the two should agree.

---

## The standard formulas

```text
RPS       = Daily Requests / 10^5 seconds
Storage   = Daily Writes x Size per Write x Timeframe in days
Bandwidth = RPS x Average Payload Size
```

Almost every calculation reduces to one of these chains:

```text
Users -> Requests -> Data -> Storage -> Bandwidth -> Servers
QPS x Request Size = Network Throughput
Events x Event Size x Retention = Storage
```

### The universal formula

```text
Users x Actions/User/Day        = Requests/Day
Requests/Day / 86400            = Average QPS
Average QPS x 3-5               = Peak QPS
Records/Day x Record Size       = Storage/Day
Storage x Replication x Indexes = Actual Storage
```

---

## The adjustments people forget

**Peak traffic factor.** Never use average QPS, because traffic is spiky. Peak is usually average times 3, sometimes times 5 or 10 for social networks. So 2,300 average QPS means roughly 7,000 peak.

**Replication factor.** Storage is never the raw number. With a replication factor of 3, 36 TB is really 108 TB. Always multiply.

**Index overhead.** Indexes may double the storage. Always add data plus indexes plus replication.

**Growth planning.** Never plan for today's traffic. 100 TB today at 50 percent yearly growth is `100 x 1.5^3`, roughly 337 TB after three years.

---

## Read and write ratios

| System | Read:Write |
| --- | --- |
| Twitter | 100:1 |
| YouTube | 1000:1 |
| WhatsApp | 1:1 |
| Banking | 3:1 |
| URL shortener | 100:1 |

This ratio drives your database, cache and replica decisions.

---

## Worked calculations

**DAU to QPS.** 10 million DAU at 20 actions each is 200 million requests per day, which is `200M / 86400`, roughly 2,300 QPS.

**Storage.** 100 million tweets a day at 1 KB each is 100 GB per day, so `100 x 365` is 36.5 TB a year.

**Bandwidth.** 10,000 QPS with a 10 KB response is 100 MB per second, which is 8.6 TB a day.

**Cache sizing.** 10 million active users with a 2 KB profile is 20 GB. Add buffer, so 40 GB.

**Server count.** Assume one server handles 1,000 QPS. For 10,000 peak QPS that is 10 servers, plus redundancy, so 15 to 20.

**CDN.** 1 million videos a day at 100 MB is 100 TB a day of upload storage. If each is watched 10 times, that is 1,000 TB a day of delivery. Storage is small, delivery is huge, which is why a [[cdn|CDN]] becomes mandatory.

**Database capacity.** 100 million user rows at 1 KB is 100 GB. Replication times 3 is 300 GB. Indexes may double it to 600 GB.

---

## Default assumptions

When the interviewer gives no numbers, these are accepted.

| Thing | Size |
| --- | --- |
| User profile | 1 KB |
| Tweet or post | 1 KB |
| Chat message | 100 bytes |
| URL mapping | 500 bytes |
| Metadata | 1 KB |
| Image | 1 MB |
| Video | 100 MB to 1 GB |

---

## The real goal

Most candidates think capacity planning is QPS calculation. It is not. The flow is:

```text
Users -> Traffic -> QPS -> Storage -> Bandwidth
      -> Find Bottleneck -> Architecture Decisions
```

---

## Worked example 1: URL shortener

**Assumptions.** 100M monthly active users, 10M URLs created per day, 100 clicks per URL.

**Writes.** `10M / 86400` is roughly 120 QPS, peak `120 x 5` is roughly 600 QPS.

**Reads.** `10M x 100` is 1 billion redirects a day, so `1B / 86400` is roughly 12K QPS, peak roughly 60K QPS.

**Storage.** Short URL 10 bytes, long URL 200 bytes, metadata 100 bytes, so about 300 bytes, rounded to 500. That is `10M x 500 bytes`, roughly 5 GB a day, 1.8 TB a year, 5.4 TB with replication, and about 8 TB after adding 50 percent for indexes.

**What it revealed.** 600 write QPS against 60,000 read QPS, a 100:1 ratio. This is overwhelmingly read heavy.

**Decisions driven by the numbers.** Because reads dominate, Redis cache, read replicas and a KV database matter. Because storage is tiny at 8 TB a year, storage is not a concern. Because bandwidth is around 60 MB per second at peak, a CDN is unnecessary.

**The learning.** This is a read scaling problem, not a storage or write scaling problem.

---

## Worked example 2: WhatsApp

**Assumptions.** 1B DAU, 50 messages per user per day.

**Traffic.** `1B x 50` is 50B messages a day, so roughly 580K QPS average and 3M peak.

**Storage.** Content 100 bytes plus metadata 100 bytes, rounded to 500 bytes. `50B x 500 bytes` is 25 TB a day, roughly 9 PB a year, or 27 PB with replication.

**Concurrent users.** At 10 percent online that is 100M concurrent. If one server handles 1M WebSocket connections, you need 100 plus connection servers before redundancy.

**Group fanout.** 100M group messages a day into groups averaging 50 users is 5B deliveries. Notice that 100M writes becomes 5B downstream operations.

**What it revealed.** The real challenge is not storage. It is 3M peak QPS, 100M concurrent connections and billions of deliveries.

**Decisions driven by the numbers.** WebSockets, persistent connections, Kafka or Pulsar, fanout services and retry queues, because HTTP polling would collapse at this scale.

**The learning.** Connection management and message throughput are bigger challenges than database size.

---

## Worked example 3: Twitter

**Assumptions.** 300M DAU, 2 tweets per day.

**Tweet traffic.** 600M tweets a day, roughly 7K QPS average, 35K peak.

**Timeline reads.** At 20 feed refreshes a day, `300M x 20` is 6B timeline requests a day, roughly 70K QPS average and 350K peak.

**Fanout.** With 200 average followers, `600M x 200` is 120B timeline insertions a day. That is the important number, not the 600M tweets.

**Storage.** At 1 KB a tweet that is 600 GB a day, roughly 219 TB a year, 650 TB replicated. Surprisingly manageable.

**What it revealed.** The expensive operation is not creating a tweet, it is generating a timeline.

**Decisions driven by the numbers.** Feed cache, timeline service, and a fanout strategy. The question becomes fanout on write or fanout on read. Normal users get fanout on write, celebrities get fanout on read.

**The learning.** Derived work is far larger than original work.

---

## Worked example 4: YouTube

**Assumptions.** 100M uploads a day at 100 MB each.

**Storage.** 10 PB a day, 3,650 PB a year, which is 3.6 EB, or roughly 11 EB replicated.

**Views.** 1B views a day at 100 MB is 100 PB a day, so `100 PB / 86400` is roughly 1.15 TB per second average, and 3 to 5 TB per second at peak.

**Transcoding.** One uploaded video becomes 240p, 480p, 720p, 1080p and 4K versions, increasing storage further.

**What it revealed.** Storage is massive, but bandwidth is even bigger.

**Decisions driven by the numbers.** CDN, edge caches, regional points of presence, video chunking and adaptive bitrate streaming. Without a CDN, origin servers die immediately.

**The learning.** Content delivery is harder than content storage.

---

## Worked example 5: Uber

**Assumptions.** 50M DAU with a location update every 5 seconds.

**Location traffic.** One user produces `86400 / 5` which is 17,280 updates a day. All users produce `50M x 17,280`, which is 864B updates a day, roughly 10M QPS average and 30 to 50M peak.

**Ride requests.** At 2 rides a day, 100M ride requests, roughly 1,200 QPS.

**The comparison.** Location updates at 10,000,000 QPS against ride requests at 1,200 QPS. A difference of roughly 8000 times.

**What it revealed.** The business operation, booking a ride, is not the scaling problem. Location updates are.

**Decisions driven by the numbers.** An in memory location store, geospatial indexes, regional sharding and streaming infrastructure. Storing every location update permanently is impossible, so you need aggressive [[ttl|TTL]], storing only the latest location rather than full history.

**The learning.** Background traffic dominates user facing traffic.

---

## The master summary

| System | Key numbers | What it revealed | Bottleneck | Decision |
| --- | --- | --- | --- | --- |
| URL shortener | 60K read QPS against 600 write QPS | read heavy system | reads | Redis, cache, read replicas |
| WhatsApp | 3M peak QPS, 100M connections | throughput plus connections | message delivery | WebSockets, Kafka, fanout |
| Twitter | 600M tweets becomes 120B feed updates | fanout explosion | timeline generation | hybrid fanout on write and read |
| YouTube | 10 PB/day storage, 100 PB/day traffic | delivery beats storage | CDN bandwidth | CDN, edge caching |
| Uber | 10M QPS location updates | background traffic dominates | real time location processing | geospatial indexing, streaming |

---

## The final mental model

Every system design interview reduces to one of five questions.

Can I handle the reads? That is the URL shortener. Can I handle the throughput? WhatsApp. Can I handle the fanout? Twitter. Can I handle the bandwidth? YouTube. Can I handle the real time updates? Uber.

The purpose of capacity planning is to identify which of those five you are actually solving. Once you know, the architecture discussion becomes dramatically easier, because you know exactly where to spend your complexity budget.

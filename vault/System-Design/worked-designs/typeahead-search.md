# Distributed Typeahead and Search

> [!tldr]
> Precompute prefixes at write time, scatter gather across shards at read time, and warm the cache actively so a popular prefix never misses.

---

## The problem

Over a billion records of contacts and companies. When a salesperson types "Micro", the system must instantly suggest "Microsoft", "MicroStrategy", or specific people at those companies.

---

## Functional requirements

**Read path.** As a user types a prefix, return the top 10 matching companies or contacts.

**Write path.** As new data is ingested from the async data pipeline, the search index must update continuously so new contacts become searchable.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale | massively read heavy. Thousands of reads per second as users type, with a steady stream of background writes |
| Performance | strict, under 50 ms. Any longer and the user has already typed the next letter, making the suggestion useless |
| Availability against consistency | high availability is mandatory. We accept eventual consistency, so a new record not appearing for 5 to 10 minutes is fine |
| Edge cases | typo tolerance, so "Gogle" suggests "Google", and ranking, so the large company beats the local shop with the same name |

---

## The architecture

To get sub 50 ms latency with typo tolerance across a billion records, a SQL `LIKE '%prefix%'` query completely melts down. You need a dedicated search engine built on Lucene.

1. **The API gateway.** Routes `GET` search requests to the stateless search microservices.
2. **The search service, read path.** Takes the prefix, checks a Redis cache, and on a miss queries the Elasticsearch cluster. If someone searches "App", millions of people do, so cache the top 10 results for "App" for 5 minutes.
3. **The Elasticsearch cluster.** Distributed nodes holding the inverted index and edge n-grams.
4. **The indexer worker, write path.** A background Kafka consumer that reads new contacts from the ingestion pipeline and asynchronously indexes them.

---

## Index mapping and edge n-grams

In a relational database you define tables. In Elasticsearch you define an index mapping. To make prefix searching fast, use an edge n-gram analyzer.

For "Microsoft", the analyzer breaks it down at write time and stores it as:

```text
M    -> Microsoft
Mi   -> Microsoft
Mic  -> Microsoft
Micr -> Microsoft
```

```json
{
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "entity_type": { "type": "keyword" },
      "name": {
        "type": "text",
        "analyzer": "autocomplete_ngram_analyzer"
      },
      "popularity_score": { "type": "integer" }
    }
  }
}
```

> [!warning] The trap
> Without a `popularity_score`, searching "App" might return "Appleton Plumbing" instead of "Apple Inc". You must sort by relevance and popularity.

---

## API design

Because this fires on every keystroke, the payload must be tiny to save bandwidth.

**Endpoint.** `GET /v1/search/typeahead?q=Micr&limit=10`

```json
{
  "results": [
    { "id": "c_123", "type": "COMPANY", "name": "Microsoft", "highlight": "Microsoft" },
    { "id": "c_456", "type": "COMPANY", "name": "MicroStrategy", "highlight": "MicroStrategy" }
  ]
}
```

---

## How we hit the NFRs

**Under 50 ms latency.** Achieved by precomputing the prefixes as edge n-grams at write time. When the user searches, Elasticsearch does a constant or logarithmic lookup on the precomputed prefix instead of scanning full strings. A Redis cache in front for common prefixes reduces latency further.

**Typo tolerance.** Lucene natively supports fuzzy matching using Levenshtein distance, so we catch minor typos without custom logic.

**Eventual consistency.** Decoupling the write path, Kafka to indexer worker, from the read path means heavy ingestion never slows down the search bar.

---

## The sharding question

**Q.** As the index grows to 1 billion records, a single node runs out of RAM and disk. You split the data across 50 servers. When a user searches "Micr", how does the gateway know which of the 50 servers holds companies starting with M?

### The trap: alphabetical sharding

A junior engineer says "route alphabetically, A to E goes to node 1, F to J to node 2".

**The catastrophe.** Data is not evenly distributed alphabetically. Millions search for "Apple" and "Amazon", so node 1's CPU hits 100 percent and melts down, while the node holding X, Y and Z sits idle. That is a hotspot.

### The true architecture: scatter gather

You do not route alphabetically. You route using a hash of the company ID, so data is mathematically balanced across all 50 nodes.

But if the data is random, how do you search for "Micro"?

**The mechanism.** The gateway sends the request to a single coordinating node. That node broadcasts `q=Micr` to all 50 shards simultaneously, the scatter.

Each node uses its internal finite state transducer, a hyper efficient in memory data structure Lucene uses for prefix matching, to find its local top 10 in under 5 ms.

The 50 nodes return results to the coordinating node, which merges and sorts the 500 total hits by `popularity_score` into the final global top 10, the gather.

---

## How Redis actually stores the cache

### The naive approach, a ZSET of raw data

A Redis sorted set where the key is the prefix, `prefix:micr`, the member is the company ID, and the score is popularity.

**The flaw.** When the gateway reads this with `ZREVRANGE prefix:micr 0 9` it only gets IDs back. It then has to make another database call to fetch the company name, logo URL and subtitle to render the UI. You just ruined your sub 50 ms latency.

### The industry standard, a materialized view

Do not use sorted sets for the final read cache. Use standard key value strings, where the value is a fully pre rendered JSON array of the top 10 results.

```text
SET prefix:micr '[{"id":"123", "name":"Microsoft", "logo":"..."}]'
```

The read is a single constant time network hop. The gateway takes the raw string and throws it directly to the user.

Sorted sets are still used internally by the background workers to calculate the maths. The final edge cache is purely JSON strings.

---

## The analytics feedback loop

How does the system know "Microsoft" should overtake "MicroStrategy" in the ranking? It requires a continuous background pipeline.

**1. The clickstream.** When a user searches "Micr" and clicks "Microsoft", the app fires a telemetry event: `{ "prefix": "micr", "clicked_id": "123", "timestamp": "..." }`.

**2. The ingestion queue.** These millions of click events bypass the main API and drop directly into a Kafka topic, `Search_Clickstream`.

**3. The stream processor.** A cluster of background workers, often Flink, Spark Streaming or Kafka consumer groups, reads the topic. They use a tumbling window of, say, 5 minutes, and calculate that `company_123` got 5,000 clicks in the last 5 minutes.

**4. Updating the source of truth.** The worker updates the `popularity_score` field inside the Elasticsearch cluster.

---

## Active cache warming, preventing the stampede

### The trap: lazy loading

Most developers set a 5 minute TTL on the Redis key. When it expires the key deletes itself, and the next user to search "Micr" gets a cache miss, forcing a query to Elasticsearch, a 50 ms wait, and a cache rewrite.

**The catastrophe.** If the key expires and in that exact millisecond 10,000 users type "Micr", you get 10,000 simultaneous cache misses, so 10,000 heavy scatter gather queries hit Elasticsearch at once and the cluster melts.

### The solution: active warming

At this scale you do not let popular prefixes expire.

1. Identify the top 10,000 most common prefixes globally, for example "A", "Ap", "App", "Mic", "Micr".
2. Run a dedicated cron worker every 2 minutes.
3. That worker intentionally fires 10,000 scatter gather queries at Elasticsearch in the background.
4. It takes the fresh top 10, formats them into JSON, and forcefully overwrites the keys in Redis.

**The result.** The Redis keys never expire, a user never experiences a cache miss for a popular term, and the background worker absorbs all the compute cost, shielding Elasticsearch from sudden traffic spikes.

---

## Does constant indexing block the live search?

In a traditional SQL database a massive `INSERT` block can cause row or table locks, forcing `SELECT` queries to wait. Elasticsearch avoids this with near real time indexing.

**1. The in memory buffer.** When the API writes a new company, the document goes into a hidden in memory buffer. It is not immediately searchable.

**2. The refresh interval.** Elasticsearch runs a background refresh, usually every 1 second, though for heavy bulk ingestion you might configure 30 seconds.

**3. The immutable segment.** During the refresh, buffered data is written to a new immutable file called a segment. Only now does the data become searchable.

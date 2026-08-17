# Geospatial Discovery API

> [!tldr]
> CQRS in its purest form. Elasticsearch answers "which ones are near me and match my filters", Redis answers "how busy are those exact ones right now".

---

## The problem

A patient wakes up with a severe cough and opens the app. They need a map and list of all urgent care clinics or available telehealth doctors within a 20 mile radius, sorted by the optimal combination of closest distance and shortest wait time.

Querying a database for geographic proximity requires calculating the Haversine formula between the user and every single clinic. A standard `SELECT * WHERE distance < 20` triggers a full table scan and kills the database CPU.

**The objective.** Execute complex spatial queries intersecting with real time volatile availability data in under 100 ms.

---

## Functional requirements

**Search.** Given a latitude, longitude and radius, or a bounding box, return nearby clinics or doctors.

**Filter.** By `care_type`, `languages_spoken` and `insurance_accepted`.

**Ranking.** Results ranked dynamically by a composite score of proximity and availability.

**Write path.** As clinics get booked up or wait times fluctuate, the search read infrastructure updates in near real time.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | extremely read heavy, roughly 100 reads per write. Map panning triggers heavy traffic. Target 20,000 read QPS |
| Performance | under 100 ms at p99, so the map UI feels fluid |
| Availability against consistency | high availability for the read path, and eventual consistency is fine. A wait time that says 15 minutes but jumped to 20 five seconds ago is acceptable for discovery |
| Concurrency | high concurrent reads during morning rushes |
| Edge cases | the edge of grid problem, dense urban clusters with thousands of results in a mile, and scrapers trying to dump the entire directory |

---

## The architecture

```text
============= THE READ PATH (DISCOVERY: < 100ms) ==========================

      +-------------------------------------------+
      |         PATIENT APP (React/Mobile)        |
      |   (Sends Lat: 47.6062, Long: -122.3321)   |
      +---------------------+---------------------+
                            | 1. GET /v1/clinics/nearby?lat=...
                            v
      +-------------------------------------------+
      |     API GATEWAY                           |
      |   (Rate limiting, Geo-IP blocking)        |
      +---------------------+---------------------+
                            | 2. Sync gRPC
                            v
      +-------------------------------------------+
      |     CARE DISCOVERY SERVICE (Node.js)      |
      |    (Stateless, geo-query orchestrator)    |
      +---------+-------------------------+-------+
                |                         |
    3. Sync TCP |                         | 4. Sync TCP
   (geo_point   |                         | (MGET clinic:1:wait, clinic:2:wait)
    Query)      v                         v
  +-------------------+        +---------------------+
  |   ELASTICSEARCH   |        |    REDIS CLUSTER    |
  | (Spatial index /  |        | (Real-time live     |
  |  geohash grid)    |        |  availability state)|
  +-------------------+        +---------------------+
  Returns top 100 clinics      Fetches live wait times for
  matching filters and radius. ONLY those 100 clinics.

================ THE WRITE PATH (UPDATES AND INGESTION) ==================

      +-------------------------------------------+
      |    APPOINTMENT ORCHESTRATOR               |
      |  (Or clinic admin portal modifying wait)  |
      +---------------------+---------------------+
                            | 5. Sync TCP (PgSQL)
                            v
                  +-------------------+
                  | POSTGRESQL        |   6. CDC Stream (Debezium)
                  | (Source of Truth) +----------------------------+
                  +-------------------+                            |
                                                                   v
           +------------------------------------------------------------+
           |                     APACHE KAFKA                           |
           | Topic: clinic.state.updates                                |
           +------------------------+-------------------------+---------+
                                    | 7a. ASYNC Poll          | 7b. ASYNC Poll
                                    v                         v
                          +------------------+      +------------------+
                          | ELASTIC INDEXER  |      | REDIS UPDATER    |
                          |   (Updates ES)   |      | (Updates Redis)  |
                          +------------------+      +------------------+
```

---

## The write path

**1. Source of truth.** A clinic admin changes the wait time from 15 to 30 minutes, or updates accepted insurances. This writes directly to PostgreSQL.

**2. CDC extraction.** Debezium tails the write ahead log. The moment the commit finishes, it extracts the row change and publishes to `clinic.state.updates`.

**3. Targeted updates.**

The **Redis updater** consumes the message. If the change was volatile, such as `wait_time`, it executes `SET clinic:123:wait 30`. Redis is updated roughly 50 ms after the admin's click.

The **Elastic indexer** consumes the message. If the change was static metadata, such as adding an insurer, it updates the Elasticsearch document. We deliberately avoid updating Elasticsearch for high frequency wait time changes, to prevent segment merge thrashing in Lucene.

---

## The read path

**4. The search.** The patient pans the map and the app fires an API call. The gateway enforces a rate limit, for example 50 requests per minute per IP, to prevent scraping, then routes to the discovery service.

**5. Spatial and metadata filtering.** The service translates the request into an Elasticsearch DSL query. Elasticsearch uses geohashes to find clinics inside the radius while applying filters like `care_type = URGENT_CARE`, returning 100 clinic IDs in roughly 15 ms.

**6. Live data hydration.** The service takes those 100 IDs and executes a single Redis `MGET`. Redis returns real time wait times for all 100 in roughly 2 ms.

**7. In memory scoring.** The service loops the 100 merged records, calculates `(Distance_Miles * W1) + (Wait_Time_Mins * W2)`, sorts, slices the top 20, and returns JSON. Total backend latency roughly 25 ms.

---

## API design

**Endpoint.** `GET /v1/clinics/discovery`

**Why GET?** Idempotent, safe, and heavily cacheable by CDNs if needed.

| Parameter | Purpose |
| --- | --- |
| `lat` and `lng` | the centre point |
| `radius_mi` | the constraint |
| `care_type` | filter |
| `insurance` | filter |
| `cursor` | pagination |

> [!warning] Cursor, not offset
> Offset requires scanning and discarding rows, which degrades exponentially at scale. A cursor is an exact pointer to the last viewed record.

**Headers.** `X-Request-ID: <UUID>` for distributed tracing across Elasticsearch and Redis.

```json
{
  "meta": {
    "total_results": 142,
    "next_cursor": "eU5iXzIwa20...",
    "processing_time_ms": 22
  },
  "data": [
    {
      "id": "cl_998",
      "name": "Providence Urgent Care - Downtown",
      "coordinates": { "lat": 47.6101, "lng": -122.3400 },
      "distance_mi": 1.2,
      "static_data": {
        "is_pediatric": true,
        "insurances": ["blue_cross", "aetna"]
      },
      "live_availability": {
        "current_wait_mins": 15,
        "calculated_score": 94.5
      }
    }
  ]
}
```

| Status | Meaning |
| --- | --- |
| `200 OK` | success |
| `400 Bad Request` | missing `lat` or `lng` |
| `429 Too Many Requests` | rate limit exceeded, includes a `Retry-After: 60` header |

---

## Database design and spatial indexing

**The PostgreSQL source of truth** uses the PostGIS extension.

**Table `clinics`.** `id` UUID primary key, `tenant_id` UUID foreign key, `name` VARCHAR, `care_type` VARCHAR, and `location` as `GEOMETRY(Point, 4326)` storing standard WGS 84 spatial data.

### How Elasticsearch finds locations in 15 ms

1. Elasticsearch divides the Earth into a grid, converting latitude and longitude into a string, so `47.6062, -122.3321` becomes something like `c23nb62w`.
2. Clinics physically close together share the same string prefix, `c23nb62w` against `c23nb62x`.
3. To find clinics within 5 miles, Elasticsearch translates the maths into a string prefix search, effectively `WHERE geohash LIKE 'c23nb%'`.
4. Because B-trees and tries are optimised for string matching, the spatial search runs in logarithmic time instead of a full table scan.

---

## Trade offs and edge cases

### Why Elasticsearch plus Redis instead of just Redis GEO

Redis has native `GEORADIUS` commands which are incredibly fast. But Redis GEO only stores the coordinate and an ID. It cannot easily execute complex boolean metadata queries such as "find clinics under 5 miles where care type is urgent and insurance is in this set and pediatric is true".

We trade architectural complexity, running two systems, to get Elasticsearch's boolean filtering combined with Redis's volatile speed.

### CQRS eventual consistency against read latency

Because we use Kafka and CDC to update the read models, there is a 1 to 3 second delay between a PostgreSQL update and the Elasticsearch or Redis update. We consciously accept that to guarantee sub 100 ms read latency.

### The edge of grid geohash problem

**The trap.** A patient stands on the border between geohash box A and box B, and a clinic is 100 feet away in box B. If Elasticsearch only searches box A, that clinic is missed.

**The defence.** The Elasticsearch `geo_distance` query automatically queries the centre geohash box and its 8 surrounding neighbours, then filters the exact maths in memory.

---

## Follow up questions

### Map panning generates massive traffic

**Q.** If a user drags the map 10 times in 3 seconds, they trigger 10 heavy Elasticsearch queries. How do you protect the backend?

**A.** Defences at two layers. On the client, debouncing: the app waits roughly 300 ms after the user stops dragging before firing. On the gateway, a token bucket rate limiter keyed by user ID or IP, capping discovery searches to 30 per minute to prevent scraping or UI bugs from overwhelming the cluster.

### Elasticsearch outage

**Q.** Does the entire discovery feature go down?

**A.** For graceful degradation, build a fallback circuit breaker in the service. If Elasticsearch times out, fall back to querying the PostgreSQL replica directly using PostGIS `ST_DWithin`.

But because PostGIS is slower under heavy load, automatically degrade the search constraints, for example ignoring secondary text filters or capping the radius to 5 miles, so the database does not crash while acting as the fallback.

### Radius against bounding box

**Q.** Radius queries are common, but map screens are rectangular. How do you avoid fetching clinics inside the radius but visually off screen in the corners?

**A.** Change the API to accept a bounding box instead of a radius. The app sends the top right and bottom left coordinates of the visible screen. The `geo_bounding_box` query is mathematically cheaper than a circular `geo_distance` query, and it perfectly matches the client viewport, eliminating over fetching.

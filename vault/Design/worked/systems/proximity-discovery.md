# Proximity and Venue Discovery

> [!tldr]
> Geospatial data is static, availability data is volatile. Couple them in one query and the index churn from bookings melts the database.

---

## The core conflict

Designing a read heavy location based service is a classic challenge.

Venue locations barely move, but availability changes every second as slots are booked. If you tightly couple them in a single database query at high scale, constant index churn from bookings drags down the performance of the geospatial maths.

---

## Level 1: the MongoDB baseline, moderate scale

At early to moderate scale, MongoDB handles this well, provided you structure the schema and indexes correctly.

### The schema strategy

Keep static venue data separate from volatile slot data, so the `2dsphere` index does not constantly recalculate when a slot is booked.

```js
// Venue collection, relatively static
{
  _id: ObjectId("..."),
  name: "Indiranagar Football Club",
  location: {
    type: "Point",
    coordinates: [77.6387, 12.9716] // [longitude, latitude], must be this order
  },
  isActive: true
}

// Availability collection, highly volatile
{
  venueId: ObjectId("..."),
  date: "2026-08-03",
  slots: {
    "18:00": "AVAILABLE",
    "19:00": "BOOKED",
    "20:00": "AVAILABLE"
  }
}
```

### The index

A compound index is best, so inactive venues are filtered out before distances are calculated.

```js
db.venues.createIndex({ isActive: 1, location: "2dsphere" });
```

### The query

Use the aggregation pipeline. The `$geoNear` stage must be the first stage to use the index.

```js
const turfs = await Venue.aggregate([
  {
    $geoNear: {
      near: { type: "Point", coordinates: [77.64, 12.97] },
      distanceField: "distance",
      maxDistance: 5000, // 5 km in metres
      query: { isActive: true }, // uses the compound index
      spherical: true
    }
  },
  { $limit: 50 } // crucial for preventing DB melt
]);

// Step 2: fetch availability only for these 50 venues
const availability = await Availability.find({
  venueId: { $in: turfs.map(t => t._id) },
  date: "2026-08-03"
});
```

### Why this eventually melts

MongoDB computes proximity mathematically using the Haversine formula on a sphere. As concurrent active users grow, computing trigonometric functions across thousands of documents on every app open exhausts the CPU.

---

## Level 2: the Redis GEO layer, high read throughput

To protect MongoDB, offload the geospatial maths to RAM. Redis has built in geospatial commands using geohashing and sorted sets, which makes radius queries very fast.

**Sync.** When a new venue is onboarded, a worker adds it to a Redis geo set.

```text
GEOADD city:bengaluru:turfs 77.6387 12.9716 "venue_id_123"
```

**Query.** When a user opens the app, query Redis using the modern `GEOSEARCH` command, which replaced `GEORADIUS`.

```js
const nearbyVenueIds = await redis.geosearch(
  'city:bengaluru:turfs',
  'FROMLONLAT', 77.64, 12.97,
  'BYRADIUS', 5, 'km',
  'ASC', 'COUNT', 50 // automatically sorts by distance
);
```

**Handling availability.** Since slot availability is volatile, store the 2 hour availability window in a fast Redis hash, `HGETALL availability:venue_id_123`. The server fetches the 50 closest venue IDs from the geo set, then fires a pipelined `MGET` to fetch their availability instantly.

---

## Level 3: spatial grids, the ride hailing and food delivery scale

At massive scale, calculating radiuses even in Redis becomes an anti pattern. Instead of asking "what points are within 5 km of my point?", you change the question into a simple string matching problem.

This is done using H3 or S2 libraries.

**How it works.**

1. The H3 library divides the entire world into interlocking hexagons.
2. When a venue is added, you calculate its H3 hexagon ID at a chosen resolution, for example resolution 8 which is roughly 0.7 square km, and save it as a plain string like `"8860145b41fffff"`.
3. When the user opens the app, the server calculates the user's current H3 hexagon ID locally.
4. Using the H3 k-ring function, the server instantly calculates the IDs of the 1 or 2 rings of adjacent hexagons that roughly equal a 5 km radius.

Now the complex geospatial query becomes a fast indexed lookup:

```sql
SELECT * FROM venues WHERE h3_index IN ('8860145b41fffff', '8860145b43fffff', ...);
```

By converting spatial maths into an indexed string lookup, the database serves thousands of concurrent requests without breaking a sweat.

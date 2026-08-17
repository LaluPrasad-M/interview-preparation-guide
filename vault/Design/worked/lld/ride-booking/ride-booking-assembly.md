# Assembly and Integration

> [!tldr]
> Wire the object graph in one place at startup, then inject the same instance everywhere.

Part of [[ride-booking]].

---

## Step 6: wire it up

```js
const VehicleType = require("./enums/VehicleType")
const Rider = require("./models/Rider")
const Driver = require("./models/Driver")
const Vehicle = require("./models/Vehicle")
const Location = require("./models/Location")
const DriverRepository = require("./repositories/DriverRepository")
const RideRepository = require("./repositories/RideRepository")
const DriverService = require("./services/DriverService")
const RideService = require("./services/RideService")
const DefaultPricingStrategy = require("./strategies/DefaultPricingStrategy")
const NearestDriverMatchingStrategy = require("./strategies/NearestDriverMatchingStrategy")

// repositories
const driverRepository = new DriverRepository()
const rideRepository = new RideRepository()

// strategies
const pricingStrategy = new DefaultPricingStrategy()
const matchingStrategy = new NearestDriverMatchingStrategy()

// services
const driverService = new DriverService(driverRepository)
const rideService = new RideService(
    rideRepository,
    driverRepository,
    pricingStrategy,
    matchingStrategy
)

// create a vehicle
const vehicle = new Vehicle("v1", VehicleType.SEDAN, "KA01AB1234")

// create a driver
const driver = new Driver("d1", "Rahul", vehicle)
driverService.registerDriver(driver)
driverService.goOnline("d1", new Location(12.91, 77.64))

// create a rider
const rider = new Rider("r1", "Aman")

// request a ride
const ride = rideService.requestRide(
    "ride1",
    rider,
    new Location(12.90, 77.60),
    new Location(12.99, 77.70)
)

console.log(ride)

rideService.startRide("ride1")
rideService.completeRide("ride1")
```

---

## The end to end request trace

**Step 0, the incoming request.**

```json
{
  "riderId": "r1",
  "pickup":  { "lat": 12.90, "lng": 77.60 },
  "dropoff": { "lat": 12.99, "lng": 77.70 }
}
```

**Step 1, the controller.** It parses the request, validates its shape, calls the service and returns the response. It must not calculate fare, match a driver or query the database, because the controller is the transport layer, not the business layer.

**Step 2, the service.** `RideService.requestRide()` is where orchestration happens. It creates the domain object with no database or HTTP logic, then calls `driverRepository.findAvailableDrivers()`. The service does not know about MongoDB, Redis, SQL or caching. It only knows it needs available drivers, which is a large architectural decoupling.

**Step 3, the repository.** Internally it may do a Redis lookup, a Mongo query, a SQL query or a cache lookup. The service does not care. That is the boundary.

**Step 4, the matching strategy.** `matchingStrategy.findDriver()`. The service does not know nearest logic, surge aware logic or pooling logic. Only "find me the best driver".

**Step 5, entity state mutation.** `ride.assignDriver(driver)`. Ride itself controls legal transitions and internal consistency. The service never writes `ride.status = ...` directly. That is the encapsulation boundary.

**Step 6, pricing.** `pricingStrategy.calculateFare()`, another independent abstraction boundary.

**Step 7, persistence.** `rideRepository.save(ride)`. The service does not know the database engine, schema, SQL or ORM.

**Step 8, the response.** The service returns the Ride and the controller formats the response.

```text
HTTP Request
     |
Controller
     |
RideService
     |
Repositories
     |
Strategies
     |
Entities
     |
Repositories
     |
Controller
     |
HTTP Response
```

---

## The composition root

A fair objection to that constructor:

```js
constructor(rideRepository, driverRepository, pricingStrategy, matchingStrategy)
```

It looks painful to instantiate manually. And it would be, if you wrote `new RideService(rideRepo, driverRepo, pricingStrategy, matchingStrategy)` again and again.

**That is why composition roots exist.** Objects are wired exactly once, in one centralised place, during app startup. Not everywhere. The controller then reuses the same instance:

```js
const controller = new RideController(rideService)
```

The object graph is created once.

> [!tip] The realisation
> Dependency injection does not mean every developer manually passes dependencies everywhere. One central bootstrap layer wires the app.

In large frameworks this is automated. Spring, NestJS and Angular ship DI or IoC containers that create dependencies, resolve the graph and inject objects. In NestJS you write `constructor(private rideService: RideService) {}` and the framework injects it. See [[abstraction-and-dependency-injection]].

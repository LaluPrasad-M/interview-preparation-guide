# Worked Example: Ride Booking

> [!tldr]
> The six step framework applied end to end. The interesting decisions are the ones we deliberately did not make: no `User` base class, no `Vehicle` hierarchy.

Follow [[how-to-do-an-lld-round]] alongside this. Every piece of code below maps to one of its steps.

---

## The layering

```text
                HTTP REQUEST
                      |
                      v
               +------------+
               | Controller |
               +------------+
                      |
                      v
               +------------+
               |  Service   |
               +------------+
                /     |      \
               v      v       v
      +----------+ +----------+ +------------+
      | Entities | | Strategy | | Repository |
      +----------+ +----------+ +------------+
                                       |
                                       v
                                 +----------+
                                 | Database |
                                 +----------+
```

---

## Step 1: identify the entities

Rider, Driver, Ride, Vehicle, Location. They qualify as entities because they represent business concepts, have identity, and contain state.

> [!warning] The decision worth defending: no `User` base class
> Rider and Driver do not share meaningful behaviour. Sharing only `id` and `name` is not sufficient reason for inheritance. Inheritance should model behavioural specialisation, not field reuse. So Rider and Driver stay independent entities.

### The project structure

```text
src/
  enums/
    RideStatus.js
    VehicleType.js
  models/
    Rider.js
    Driver.js
    Vehicle.js
    Location.js
    Ride.js
  repositories/
    DriverRepository.js
    RideRepository.js
  strategies/
    PricingStrategy.js
    DefaultPricingStrategy.js
    DriverMatchingStrategy.js
    NearestDriverMatchingStrategy.js
  services/
    DriverService.js
    RideService.js
  RideApp.js
```

---

## Step 2: define the states

Backend systems are mostly state transition systems, so define states early.

```js
const RideStatus = {
   REQUESTED: "REQUESTED",
   DRIVER_ASSIGNED: "DRIVER_ASSIGNED",
   IN_PROGRESS: "IN_PROGRESS",
   COMPLETED: "COMPLETED",
   CANCELLED: "CANCELLED"
}

module.exports = RideStatus
```

**Why an enum?** Without one, `ride.status = "started"`, `"START"` and `"starteddd"` all become possible. Enums centralise the allowed states, reduce typos and improve transition safety.

```js
const VehicleType = {
   BIKE: "BIKE",
   SEDAN: "SEDAN",
   SUV: "SUV"
}

module.exports = VehicleType
```

> [!warning] Why an enum instead of a Vehicle hierarchy
> We deliberately avoid `Vehicle -> Bike -> Sedan`, because vehicles currently have no different behaviour, only a different type. Inheritance there would be premature abstraction.

---

## Step 3: the entity classes

Entities contain state, identity and state specific behaviour. They must not orchestrate workflows, query the database, perform matching or calculate pricing.

```js
class Location {
   constructor(lat, lng) {
       this.lat = lat
       this.lng = lng
   }
}

module.exports = Location
```

**Why a separate Location class?** Instead of `pickupLat` and `pickupLng` everywhere, we encapsulate coordinates into a domain object, which improves readability and leaves room for geospatial utilities later.

```js
class Vehicle {
   constructor(id, type, plateNumber) {
       this.id = id
       this.type = type
       this.plateNumber = plateNumber
   }
}

module.exports = Vehicle
```

Driver HAS-A Vehicle, which is composition. A vehicle is not a driver.

```js
class Rider {
   constructor(id, name) {
       this.id = id
       this.name = name
   }
}

module.exports = Rider
```

Rider is minimal because it currently represents only identity and a domain actor. Adding ride orchestration, pricing logic or database access would violate single responsibility.

```js
class Driver {
   constructor(id, name, vehicle) {
       this.id = id
       this.name = name
       this.vehicle = vehicle
       this.isOnline = false
       this.currentLocation = null
       this.activeRideId = null
   }

   goOnline(location) {
       this.isOnline = true
       this.currentLocation = location
   }

   goOffline() {
       this.isOnline = false
   }

   assignRide(rideId) {
       if (this.activeRideId) {
           throw new Error("Driver already has active ride")
       }
       this.activeRideId = rideId
   }

   completeRide() {
       this.activeRideId = null
   }

   updateLocation(location) {
       this.currentLocation = location
   }
}

module.exports = Driver
```

**Why `assignRide()` instead of external mutation?** The entity should protect its own invariants. Without it, `driver.activeRideId = rideId` could happen anywhere. Now Driver controls whether the assignment is legal and whether the invariant breaks. That is encapsulation.

### The most important entity

```js
const RideStatus = require("../enums/RideStatus")

class Ride {
   constructor(id, rider, pickup, dropoff) {
       this.id = id
       this.rider = rider
       this.driver = null
       this.pickup = pickup
       this.dropoff = dropoff
       this.status = RideStatus.REQUESTED
       this.fare = 0
   }

   assignDriver(driver) {
       if (this.status !== RideStatus.REQUESTED) {
           throw new Error("Driver cannot be assigned")
       }
       this.driver = driver
       this.status = RideStatus.DRIVER_ASSIGNED
   }

   startRide() {
       if (this.status !== RideStatus.DRIVER_ASSIGNED) {
           throw new Error("Ride cannot start")
       }
       this.status = RideStatus.IN_PROGRESS
   }

   completeRide() {
       if (this.status !== RideStatus.IN_PROGRESS) {
           throw new Error("Ride cannot complete")
       }
       this.status = RideStatus.COMPLETED
   }

   cancelRide() {
       if (this.status === RideStatus.COMPLETED) {
           throw new Error("Completed ride cannot cancel")
       }
       this.status = RideStatus.CANCELLED
   }

   setFare(fare) {
       this.fare = fare
   }
}

module.exports = Ride
```

**Why is transition logic inside Ride?** Because Ride owns ride state. The bad alternative is `ride.status = "COMPLETED"` scattered across services, which creates invalid transitions, broken workflows and inconsistent state.

---

## Step 4: workflows become services

```js
class DriverRepository {
   constructor() {
       this.drivers = new Map()
   }

   save(driver) {
       this.drivers.set(driver.id, driver)
   }

   findById(driverId) {
       return this.drivers.get(driverId)
   }

   findAvailableDrivers() {
       return [...this.drivers.values()]
           .filter(driver => driver.isOnline && !driver.activeRideId)
   }
}

module.exports = DriverRepository
```

**Why a repository?** Without one, services become tightly coupled to the database. The repository abstracts persistence. Today it is an in memory `Map`, tomorrow it is MongoDB or PostgreSQL, without changing service logic.

```js
class RideRepository {
   constructor() {
       this.rides = new Map()
   }

   save(ride) {
       this.rides.set(ride.id, ride)
   }

   findById(rideId) {
       return this.rides.get(rideId)
   }
}

module.exports = RideRepository
```

---

## Step 5: change points become abstractions

Ask what behaviour may vary later. Here it is pricing and driver matching. Those are true change points, so now abstractions make sense.

```js
class PricingStrategy {
   calculateFare(ride) {
       throw new Error("Method not implemented")
   }
}

module.exports = PricingStrategy
```

```js
const PricingStrategy = require("./PricingStrategy")

class DefaultPricingStrategy extends PricingStrategy {
   calculateFare(ride) {
       return 100
   }
}

module.exports = DefaultPricingStrategy
```

This is real polymorphism, because `RideService` can now use a default, surge or night pricing strategy through the same `calculateFare()` interface without modification.

```js
class DriverMatchingStrategy {
   findDriver(drivers, pickupLocation) {
       throw new Error("Method not implemented")
   }
}

module.exports = DriverMatchingStrategy
```

```js
const DriverMatchingStrategy = require("./DriverMatchingStrategy")

class NearestDriverMatchingStrategy extends DriverMatchingStrategy {
   findDriver(drivers, pickupLocation) {
       if (!drivers.length) {
           return null
       }
       return drivers[0]
   }
}

module.exports = NearestDriverMatchingStrategy
```

Matching logic changes independently from the ride workflow, which is exactly when [[strategy]] earns its place.

---

## The services

```js
class DriverService {
   constructor(driverRepository) {
       this.driverRepository = driverRepository
   }

   registerDriver(driver) {
       this.driverRepository.save(driver)
   }

   goOnline(driverId, location) {
       const driver = this.driverRepository.findById(driverId)
       driver.goOnline(location)
   }

   updateLocation(driverId, location) {
       const driver = this.driverRepository.findById(driverId)
       driver.updateLocation(location)
   }
}

module.exports = DriverService
```

```js
const Ride = require("../models/Ride")

class RideService {
   constructor(rideRepository, driverRepository, pricingStrategy, matchingStrategy) {
       this.rideRepository = rideRepository
       this.driverRepository = driverRepository
       this.pricingStrategy = pricingStrategy
       this.matchingStrategy = matchingStrategy
   }

   requestRide(rideId, rider, pickup, dropoff) {
       const ride = new Ride(rideId, rider, pickup, dropoff)

       const availableDrivers = this.driverRepository.findAvailableDrivers()

       const selectedDriver = this.matchingStrategy.findDriver(availableDrivers, pickup)

       if (!selectedDriver) {
           throw new Error("No drivers available")
       }

       ride.assignDriver(selectedDriver)
       selectedDriver.assignRide(ride.id)

       const fare = this.pricingStrategy.calculateFare(ride)
       ride.setFare(fare)

       this.rideRepository.save(ride)

       return ride
   }

   startRide(rideId) {
       const ride = this.rideRepository.findById(rideId)
       ride.startRide()
   }

   completeRide(rideId) {
       const ride = this.rideRepository.findById(rideId)
       ride.completeRide()
       ride.driver.completeRide()
   }

   cancelRide(rideId) {
       const ride = this.rideRepository.findById(rideId)
       ride.cancelRide()

       if (ride.driver) {
           ride.driver.completeRide()
       }
   }
}

module.exports = RideService
```

`RideService` exists because this workflow touches Ride, Driver, the pricing strategy, the matching strategy and the repositories. That is orchestration, which is the perfect service responsibility.

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

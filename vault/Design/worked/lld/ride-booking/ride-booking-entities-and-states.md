# Entities and State Machine

> [!tldr]
> Define the domain entities and the state transitions they enforce, before writing services.

Part of [[ride-booking]].

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

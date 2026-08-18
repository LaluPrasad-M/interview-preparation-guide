# Repositories, Strategies, and Services

> [!tldr]
> Repositories abstract persistence. Strategies abstract behavior variation. Services orchestrate the workflow.

Part of [[ride-booking]].

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

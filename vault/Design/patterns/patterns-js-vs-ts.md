# Patterns: JavaScript against TypeScript

> [!tldr]
> Node.js gives you two of these patterns for free. The module cache is a singleton, and `EventEmitter` is an observer. Both have caveats worth knowing.

Each pattern's own note has the concept and the canonical implementation. This note is the language comparison and the Node specific behaviour.

---

## Singleton

**TypeScript** enforces it structurally at compile time with a `private` constructor and a `static` instance.

**JavaScript** gets it naturally from Node's module caching system. When you `require()` or `import` a file multiple times, Node evaluates it once and returns the cached exports.

```typescript
class DatabaseConnection {
  private static instance: DatabaseConnection;
  private connectionStatus: boolean = false;

  // 1. The compiler strictly forbids 'new DatabaseConnection()' outside this class
  private constructor() {
    this.connectionStatus = true;
  }

  // 2. Controlled access point
  public static getInstance(): DatabaseConnection {
    if (!DatabaseConnection.instance) {
      DatabaseConnection.instance = new DatabaseConnection();
    }
    return DatabaseConnection.instance;
  }
}
// Under the hood: the 'private' keyword is stripped. In JS, someone could still
// call 'new DatabaseConnection()' if they bypassed the type checker.
```

```javascript
// database.js
class DatabaseConnection {
  constructor() {
    this.connectionStatus = true;
  }
}

// Under the hood: Node caches the evaluated export. Any file importing this
// module gets the exact same object reference in memory. No static needed.
const instance = new DatabaseConnection();
module.exports = instance;
```

> [!warning] The module cache pitfall
> Node's module cache is keyed by the absolute file path. On a case insensitive filesystem, requiring `./DBConnection.js` in one file and `./dbconnection.js` in another creates two separate instances, because Node resolves them as different cache keys.
>
> The cache is also not shared if you have multiple versions of a package in your `node_modules` tree, or if you use worker threads. Either one breaks the singleton guarantee and can exhaust database connection limits.

See [[singleton]] for the lazy, eager and ES module forms.

---

## Factory

TypeScript uses interfaces to guarantee whatever the factory returns adheres to a strict contract. JavaScript simply returns the object and relies on duck typing.

```typescript
interface DataParser { parse(file: Buffer): object; }

class CSVParser implements DataParser { parse(file: Buffer) { return { type: 'csv' }; } }
class XMLParser implements DataParser { parse(file: Buffer) { return { type: 'xml' }; } }

class ParserFactory {
  // TS ensures the returned object always has a parse() method
  static createParser(mimeType: string): DataParser {
    switch (mimeType) {
      case 'text/csv': return new CSVParser();
      case 'text/xml': return new XMLParser();
      default: throw new Error("Unsupported format");
    }
  }
}
```

```javascript
class CSVParser { parse(file) { return { type: 'csv' }; } }
class XMLParser { parse(file) { return { type: 'xml' }; } }

class ParserFactory {
  static createParser(mimeType) {
    // JS evaluates this dynamically. It returns an instance,
    // assuming the caller knows to call .parse() on it.
    const parsers = {
      'text/csv': CSVParser,
      'text/xml': XMLParser
    };

    const ParserClass = parsers[mimeType];
    if (!ParserClass) throw new Error("Unsupported format");
    return new ParserClass();
  }
}
```

The map lookup form is worth remembering. It replaces the `switch` and makes adding a format a one line change.

---

## Strategy

Strategy is very similar to factory. Factory is about creation, and strategy is about behaviour and execution. TypeScript enforces the contract via interfaces, JavaScript relies on the injected object having the right method.

```typescript
interface EncryptionStrategy { encrypt(data: string): string; }

class AESEncryption implements EncryptionStrategy {
  encrypt(data: string) { return `AES_ENCRYPTED_${data}`; }
}

class RSAEncryption implements EncryptionStrategy {
  encrypt(data: string) { return `RSA_ENCRYPTED_${data}`; }
}

// The context class
class SecurePayloadService {
  constructor(private strategy: EncryptionStrategy) {}

  // The strategy can be swapped at runtime
  setStrategy(strategy: EncryptionStrategy) { this.strategy = strategy; }

  process(data: string) { return this.strategy.encrypt(data); }
}
```

```javascript
class AESEncryption { encrypt(data) { return `AES_ENCRYPTED_${data}`; } }
class RSAEncryption { encrypt(data) { return `RSA_ENCRYPTED_${data}`; } }

class SecurePayloadService {
  // JS expects the injected strategy to have an encrypt() method on its prototype
  constructor(strategy) { this.strategy = strategy; }
  setStrategy(strategy) { this.strategy = strategy; }
  process(data) { return this.strategy.encrypt(data); }
}
```

---

## Observer

You can write this from scratch in TypeScript using interfaces, but Node implements it natively via `EventEmitter`.

```typescript
interface Observer { update(event: string): void; }

class KafkaMonitor implements Observer {
  update(event: string) { console.log(`Kafka reacted to: ${event}`); }
}

class IngestionSubject {
  private observers: Observer[] = [];

  attach(obs: Observer) { this.observers.push(obs); }
  notify(event: string) { this.observers.forEach(obs => obs.update(event)); }
}
```

```javascript
const EventEmitter = require('events');

// Node provides the observer pattern out of the box
class IngestionSubject extends EventEmitter {
  processFile() {
    // Emitting an event, meaning notifying observers
    this.emit('fileProcessed', { status: 'success' });
  }
}

const ingestion = new IngestionSubject();

// Attaching an observer
ingestion.on('fileProcessed', (data) => {
  console.log('Observer 1 reacted: DB Log updated', data);
});
```

---

## The interview answers

### The Node singleton and its pitfall

"In a traditional OO language, singleton uses a private constructor and a static instance. We can replicate that in TypeScript for compile time safety, but in pure Node we almost exclusively rely on the module caching system.

We instantiate the class once inside the file and export that instance with `module.exports`. Because Node caches evaluated modules, every other file that requires it receives the exact same object reference.

The critical pitfall is that the cache is keyed by absolute file path. On a case insensitive filesystem like macOS or Windows, requiring `./DBConnection.js` in one file and `./dbconnection.js` in another creates two separate instances, because Node resolves them as different keys. And if you have multiple versions of a package in your `node_modules` tree, or you use worker threads, the cache is not shared, which breaks the guarantee and can exhaust database connection limits."

### Factory against strategy

"The core difference is purpose. Factory is creational, strategy is behavioural.

Factory instantiates objects, hiding the logic of which class to construct based on dynamic input. In an ingestion framework processing multiple file formats, a `ParserFactory` reads the MIME type and decides whether to return a `CSVParser`, `JSONParser` or `XMLParser`. The caller does not care how it was created, it just wants something with a `parse()` method.

Strategy deals with execution. It encapsulates different algorithms and lets them be swapped at runtime within a single context. In a cryptography service supporting bring your own key, the context class stays the same, but depending on the tenant's configuration I inject either an AES strategy or an RSA strategy. The object already exists; strategy dictates how it behaves when `encrypt()` is called."

### Why observer matters for Node performance

"In Node the observer pattern is woven into the core through `EventEmitter`. We rarely write custom subject and observer interfaces. Our classes extend `EventEmitter`, act as the subject via `this.emit('eventName', payload)`, and the observers are callbacks attached with `.on('eventName', callback)`.

Observer decouples the registration controller from everything that must happen afterwards. When a user registers, the controller saves the user and emits a `userRegistered` event, and independent modules handle the welcome email, the CRM update and the search index write. Adding a fifth consequence means adding a listener, not editing the controller."

> [!warning] `emit()` is synchronous, and this is the trap
> `EventEmitter.emit()` invokes every listener on the same call stack, in registration order, before `emit()` returns. Emitting does not defer anything and does not free the event loop.
>
> ```js
> s.on('evt', () => console.log('2. listener ran'));
> console.log('1. before emit');
> s.emit('evt');
> console.log('3. after emit');
> // 1, then 2, then 3
> ```
>
> So observer buys you decoupling, not asynchrony. If a listener does slow synchronous work, it blocks the response exactly as an inline call would. To actually get work off the current tick you need the listener itself to do async I/O, or to hand off to `setImmediate`, a job queue or Kafka. See [[campaign-messaging-engine]] for the real version of that hand off.

# Inheritance against Composition

> [!tldr]
> Inheritance is an is-a relationship and locks you into a family tree. Composition is a has-a relationship and lets you build with LEGO blocks.

---

## The concept

Inheritance models an is-a relationship, where a child class derives its structure and behaviour from a parent.

Composition models a has-a relationship, where a class achieves complex functionality by combining instances of other independent classes.

---

## Why we avoid inheritance

**The fragile base class problem.** Inheritance creates incredibly tight coupling. A single modification to a method in a parent class can unexpectedly break all derived child classes, which makes maintenance risky.

**Deep, rigid hierarchies.** As systems scale, inheritance trees become deep and tangled. Understanding a single subclass often means reading through multiple layers of parents.

**The gorilla and banana problem.** Subclasses inherit everything from the parent, even what they do not need. You ask for a banana, but you get a gorilla holding the banana and the entire jungle. That causes memory bloat and violates single responsibility.

**No multiple inheritance.** JavaScript and TypeScript do not support it. If a class needs behaviours from two different base classes, inheritance hits a hard structural limit.

---

## Why composition solves this

**Loose coupling.** Composition relies on injecting small, single purpose objects. Modifying one component does not ripple through an entire class hierarchy.

**Dynamic flexibility.** You can swap or modify behaviours at runtime. You build objects like LEGO blocks, mixing and matching interfaces to create exactly what you need, without being locked into a family tree.

---

## The code, side by side

```typescript
// The inheritance way, rigid and tightly coupled
class BaseDataProcessor {
  parse() { /* parsing logic */ }
  saveToDB() { /* db logic */ }
}

class UserProcessor extends BaseDataProcessor {
  process() {
    this.parse();
    this.saveToDB();
  }
}
// What if we need a processor that parses but saves to a message queue
// instead of a DB? We are stuck, because saveToDB is hardcoded into the base.

// The composition way, flexible and modular
interface Parser { parse(data: any): any; }
interface Storage { save(data: any): void; }

class JSONParser implements Parser {
  parse(data: any) { return JSON.parse(data); }
}

class PostgresStorage implements Storage {
  save(data: any) { console.log("Saving to DB"); }
}

class KafkaStorage implements Storage {
  save(data: any) { console.log("Publishing to Kafka"); }
}

class DataPipeline {
  // The class has a parser and has a storage.
  constructor(private parser: Parser, private storage: Storage) {}

  execute(raw: any) {
    const parsed = this.parser.parse(raw);
    this.storage.save(parsed);
  }
}

// Now we assemble the pipeline dynamically, changing no base classes
const dbProcessor = new DataPipeline(new JSONParser(), new PostgresStorage());
const kafkaProcessor = new DataPipeline(new JSONParser(), new KafkaStorage());
```

---

## The full interview answer

**Question.** We often hear the principle "favour composition over inheritance". Why is this practically important in a Node.js backend, and what specific problems does inheritance introduce?

**Answer.** "In backend development, favouring composition over inheritance is critical because it prioritises modularity, loose coupling and long term maintainability. Inheritance models an is-a relationship, which forces a strict, rigid class hierarchy. Composition models a has-a relationship, where we build complex objects by injecting smaller, independent components.

Inheritance introduces several major problems as an application scales. The most significant is the fragile base class problem. Because child classes are tightly coupled to their parents, a bug fix or feature addition in the base class can cause unintended side effects across the entire application.

Additionally, inheritance forces subclasses to inherit unnecessary data and methods, which wastes memory and breaks the single responsibility principle. Furthermore, JavaScript and TypeScript do not support multiple inheritance. If a new service requires functionality from two separate base classes, inheritance cannot solve the problem elegantly.

Composition solves these issues by decoupling behaviours. Instead of extending a massive base class, I define small, focused interfaces such as an `Authenticator`, a `Logger` or a `DatabaseConnector`, and inject them into my main class via the constructor. If I need to change how a service authenticates, I pass it a new `Authenticator` component. I do not have to rewrite a base class, my unit tests remain isolated, and the architecture stays flexible enough to adapt to changing business requirements."

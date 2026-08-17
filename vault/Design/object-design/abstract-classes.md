# Abstract Classes

> [!tldr]
> An abstract class is one you cannot instantiate, meant to be inherited from. An abstract method is declared without a body, and every subclass must implement it. Together they let a base class say "every one of you will have this, and each of you decides how".

The idea belongs to object oriented design rather than to one language. TypeScript spells it `abstract`, and so do Java, C#, PHP and Kotlin. C++ gets the same effect with a pure virtual method, and Python with the `abc` module.

---

## What abstract does

**Abstract classes** cannot be instantiated directly. They exist to be subclassed, and their abstract methods must be implemented by the derived class.

**Abstract methods** are declared but not implemented in the abstract class. A subclass has to provide the implementation.

---

## With abstract

```typescript
abstract class Animal {
  abstract makeSound(): void; // Abstract method

  move(): void {
    console.log("Moving...");
  }
}

class Dog extends Animal {
  makeSound(): void {
    console.log("Bark!");
  }
}

const dog = new Dog();
dog.makeSound(); // Output: Bark!
dog.move(); // Output: Moving...
```

`move()` has a body. This is the point of an abstract class: abstract methods for what each subclass must decide, ordinary methods for the behaviour they all share. `new Animal()` would be a compile error, because there is no sound for a generic animal to make.

---

## Without abstract

```typescript
class Animal {
  makeSound(): void {
    console.log("Some sound");
  }

  move(): void {
    console.log("Moving...");
  }
}

const animal = new Animal();
animal.makeSound(); // Output: Some sound
animal.move(); // Output: Moving...
```

Two things changed. `Animal` can now be instantiated directly, and `makeSound` has to have an implementation, because a method with no body is only legal when marked `abstract`.

---

## Abstract class or interface

Both describe a contract, and the question of which to use comes up constantly.

| | Abstract class | Interface |
| --- | --- | --- |
| Can hold implemented methods | yes, like `move()` above | no, it is only a shape |
| Can hold state | yes | no |
| How many can a class take | one, in most languages | as many as you like |
| Survives compilation | yes, it is a real class | no in TypeScript, it is erased |

The short rule: reach for an abstract class when subclasses share real behaviour you do not want to write twice, and an interface when you only need to agree on a shape.

See [[access-modifiers]] for controlling what subclasses can reach.

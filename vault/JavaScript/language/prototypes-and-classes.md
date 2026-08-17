# Prototypes and Classes

> [!tldr]
> An ES6 `class` is a nicer way to write a constructor function. Both build objects the same way underneath, through the prototype chain.

---

## Constructor function, two ways

**Methods on the prototype.** One copy, shared by every instance.

```js
function Person(name) {
  this.name = name;
}

Person.prototype.run = function () {
  console.log(this.name, 'is running');
};

Person.prototype.walk = function () {
  console.log(this.name, 'is walking');
};
```

**Methods inside the constructor.** A fresh copy for every instance.

```js
function Person(name) {
  this.name = name;

  this.run = function () {
    console.log(this.name, 'is running');
  };

  this.walk = function () {
    console.log(this.name, 'is walking');
  };
}
```

Both work the same way:

```js
const person1 = new Person('Alice');
person1.run();   // Alice is running
```

> [!warning] The second version wastes memory
> Ten thousand instances means twenty thousand function objects, all identical. On the prototype there are two total. Put methods on the prototype unless a method needs to capture something per instance.

---

## The ES6 class

```js
class Person {
  constructor(name) {
    this.name = name;
  }

  run() {
    console.log(this.name, 'is running');
  }

  walk() {
    console.log(this.name, 'is walking');
  }
}
```

Methods in a class body land on the prototype automatically. This is the first constructor version with less typing. Two real differences: a class is not hoisted the way a function declaration is, and calling one without `new` throws instead of silently doing the wrong thing.

---

## Where the lookup goes

```js
const obj = { name: 'John', age: 30 };
console.log(obj.hasOwnProperty('name'));  // true

const obj2 = Object.create(obj);
console.log(obj2.name);                   // 'John', found on the prototype
console.log(obj2.hasOwnProperty('name')); // false, it is not obj2's own
```

Reading a property walks up the chain until it finds one. `hasOwnProperty` refuses to walk. That is exactly why it exists: it answers "is this really mine" rather than "can I see it".

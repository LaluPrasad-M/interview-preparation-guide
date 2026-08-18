# Access Modifiers

> [!tldr]
> Three levels of reach for a method or property. They are how a class decides what the outside world may touch, which is the whole of encapsulation in one keyword.

---

## The three

| Modifier | Reachable from |
| --- | --- |
| `public` | anywhere. The default when you write nothing |
| `protected` | the class and its subclasses |
| `private` | only inside the class itself |

`protected` is the one that pairs with [[abstract-classes]]: it lets a base class share something with its subclasses without exposing it to callers.

```typescript
class Account {
  public id: string;          // anyone
  protected balance: number;  // this class and subclasses
  private pin: string;        // this class only
}
```

---

## Choosing

Start at `private` and widen only when something outside genuinely needs it. That way the surface that other code can depend on stays small, and a small surface is what lets you change the inside later without breaking callers.

The mistake in the other direction is a class where everything is `public`, which technically compiles and gives you no encapsulation at all: every field becomes part of the contract, so any change to any of them is a change that other code can feel.

---

## The TypeScript caveat

> [!warning] These are compile time only
> TypeScript's `private` disappears when the code becomes JavaScript, so nothing stops a caller reaching the field at runtime. It catches your own mistakes, not an attacker's.
>
> For real enforcement use a `#field`, which is a JavaScript private field and stays private after compilation:
>
> ```typescript
> class Account {
>   #pin: string;      // genuinely inaccessible from outside, at runtime
> }
> ```

In Java or C# the modifier is enforced by the runtime, so the distinction does not arise there. It is worth knowing which kind of language you are talking about when an interviewer asks whether `private` is secure.

---

## Getters and setters

A private field with no way to read or write it from outside is often too strict. Getters and setters give controlled access back, without dropping encapsulation, since you can validate or transform the value on the way in or out.

```typescript
class Account {
  #balance: number;

  constructor(balance: number) {
    this.#balance = balance;
  }

  get balance(): number {
    return this.#balance;
  }

  set balance(value: number) {
    if (value < 0) throw new Error("Balance cannot go negative");
    this.#balance = value;
  }
}

const acc = new Account(100);
acc.balance = 50;         // runs the setter, validates first
console.log(acc.balance); // runs the getter
```

The caller writes `acc.balance = 50` like a plain property assignment, but the setter's validation still runs. That is the whole point: the external interface stays simple while the internal rule gets enforced.

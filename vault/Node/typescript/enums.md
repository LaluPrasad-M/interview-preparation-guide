# Enums

> [!tldr]
> TypeScript enums look convenient and cause real bugs the moment their values cross a network. A union of string literals does the same job without the trap.

---

## Default enums are numbers

```ts
enum LoginMode {
  email,
  social
}

LoginMode.email;   // 0
LoginMode.social;  // 1
```

> [!warning] This breaks the day someone adds a value
> The numbers come from the order of the lines. Add `app` at the top and `email` silently becomes 1. Anything that stored or sent the old number now means something else, and reordering the lines is just as bad. Nothing fails loudly. The data quietly changes meaning.

---

## Number enums

Setting the numbers yourself fixes the reordering problem, and gives you reverse lookup.

```ts
enum LoginMode {
  app = 0,
  email = 1,
  social = 2
}

LoginMode.app;     // 0
LoginMode[0];      // 'app'

Object.keys(LoginMode); // ['0', '1', '2', 'app', 'email', 'social']
```

That key list is worth remembering. A number enum compiles to an object holding both directions, which is why the keys look doubled.

---

## String enums

```ts
enum LoginMode {
  app = 'appLogin',
  email = 'emailLogin',
  social = 'socialLogin',
}

LoginMode.app;             // 'appLogin'
LoginMode['appLogin'];     // Error, no reverse lookup for string enums
Object.keys(LoginMode);    // ['app', 'email', 'social']
```

Safe over a network, since the value no longer depends on position. But the enum type is closed:

```ts
function initiateLogin(loginMode: LoginMode) { }

initiateLogin('appLogin');      // Error: not assignable to type LoginMode
initiateLogin(LoginMode.app);   // must use the enum itself
```

Every caller now has to import the enum to say a word it already knows.

---

## The alternative that avoids all of it

```ts
type LoginMode = 'appLogin' | 'emailLogin' | 'socialLogin';

function initiateLogin(loginMode: LoginMode) { }

initiateLogin('appLogin');      // works
```

| | Number enum | String enum | Union of literals |
| --- | --- | --- | --- |
| Safe to send over a network | no | yes | yes |
| Callers can pass a plain string | no | no | yes |
| Survives reordering | only with explicit values | yes | yes |
| Exists at runtime | yes, as an object | yes, as an object | no, erased at compile time |

The last row is the real argument. A union is a compile time check that costs nothing at runtime, and a typo is still a compile error.

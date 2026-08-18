# Modules: ES Modules vs CommonJS

> [!tldr]
> Two module systems in one language. ES Modules use `import` and load asynchronously. CommonJS uses `require` and loads synchronously. Node runs both, which is why the confusion never ends.

---

## The comparison

| | ES Module | CommonJS |
| --- | --- | --- |
| **File** | `.mjs`, or `.js` with `"type": "module"` in package.json | `.js` |
| **Import** | `import { myFunc } from './myModule.js';` | `const myFunc = require('./myModule');` |
| **Export** | `export const myFunc = () => {};` | `module.exports.myFunc = () => {};` |
| **Default export** | `export default function myFunc() {}` | `module.exports = function myFunc() {};` |
| **Loading** | asynchronous | synchronous |
| **Dynamic import** | `import('./mod.js').then(...)` | `require('./mod')` anywhere, including inside an `if` |
| **Scope** | variables stay private to each module | variables and functions can be shared through `module.exports` |
| **Top level `this`** | `undefined` | the `exports` object, so `{}` |
| **Top level await** | allowed | not allowed |
| **Where it fits** | browsers and modern Node | Node, mostly older code |

---

## Same file, both ways

```js
// ES Module
import express from 'express';

function createServer(app) {
  app.listen(3000, () => console.log('Server listening on port 3000'));
}

export const pi = 3.14;
export default { express, createServer };
```

```js
// CommonJS
const express = require('express');

function createServer(app) {
  app.listen(3000, () => console.log('Server listening on port 3000'));
}

module.exports.pi = 3.14;
module.exports = { express, createServer };   // this line replaces the one above
```

> [!warning] The CommonJS export footgun
> `module.exports.pi = 3.14` adds a property. `module.exports = { ... }` replaces the whole object, so anything you attached before it is gone. Assign the object once, or attach properties, but do not do both.

---

## Circular dependencies

Both systems allow two files to import each other. Both handle it badly. With `require`, one of the two gets a partially built object. A function you expected is `undefined` when you call it. The fix is almost always to move the shared piece into a third module, not to outsmart the loader.

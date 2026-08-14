# HTTP Module Server

> [!tldr]
> A server with no framework, using only Node's built in `http` module. Worth knowing because it shows you what Express is doing for you.

---

## The smallest server

```js
const http = require('http');
const PORT = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello, World!');
});

server.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
```

`res.end` sends the response and closes it. `res.write` sends a piece and leaves it open, so you still have to call `end` afterwards.

---

## Routing and reading the query string

```js
const http = require('http');
const url = require('url');
const PORT = 3000;

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);  // true parses the query string
  const pathname = parsedUrl.pathname;
  const userName = parsedUrl.query.name;

  res.setHeader('Content-Type', 'application/json');

  if (pathname === '/') {
    res.statusCode = 200;
    res.end(JSON.stringify({ message: `Hi ${userName}! Welcome to Home Page` }));
  } else if (pathname === '/about') {
    res.statusCode = 200;
    res.end(JSON.stringify({ message: `Hi ${userName}! This is our About Page` }));
  } else {
    res.statusCode = 404;
    res.end(JSON.stringify({ message: 'Page not Found' }));
  }
});

server.listen(PORT);
```

There is no router here. Routing is an `if` chain on `pathname`, which is exactly what a framework replaces.

---

## Reading a POST body

```js
const server = http.createServer((req, res) => {
  if (req.method === 'POST') {
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => {
      res.statusCode = 200;
      res.end(`Received data: ${data}`);
    });
  } else {
    res.statusCode = 404;
    res.end('Page Not Found');
  }
});
```

> [!tip] This is why express.json() exists
> The body arrives in chunks, as a stream, so you have to collect it before you can use it. `express.json()` is this listener plus a `JSON.parse`.

---

## Middleware, by hand

Middleware is just a list of functions, each given a `next` to call when it is done.

```js
const logger = (req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
};

const validateName = (req, res, next) => {
  const userName = url.parse(req.url, true).query.name;
  if (!userName) {
    res.statusCode = 400;
    res.end(JSON.stringify({ message: 'Name query parameter is required' }));
  } else {
    req.userName = userName;   // hand the value to the next handler
    next();
  }
};

const applyMiddleware = (middlewares, req, res, finalHandler) => {
  const execute = (index) => {
    if (index < middlewares.length) {
      middlewares[index](req, res, () => execute(index + 1));
    } else {
      finalHandler(req, res);
    }
  };
  execute(0);
};
```

Two details carry the whole pattern. A middleware that does not call `next` ends the request, which is how `validateName` rejects a bad one. And each middleware can attach things to `req`, which is how later handlers receive its work.

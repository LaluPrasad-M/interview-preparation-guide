# Express Server

> [!tldr]
> The same server as the http module version, minus the plumbing. Routes, params, query strings and a full CRUD API.

---

## Basic server

```js
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => res.status(200).send({ message: 'HOME' }));
app.get('/about', (req, res) => res.status(200).send({ message: 'ABOUT' }));

app.use((req, res) => res.status(404).send({ message: 'PAGE NOT FOUND' }));

app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
```

The `app.use` at the end is the catch all. Order matters: it must come after the routes, because Express walks them top to bottom and stops at the first match.

---

## Params and query

```js
// GET /contact/admin
app.get('/:path', (req, res) => res.send({ message: `GET. ${req.params.path}` }));
app.get('/:path1/:path2', (req, res) =>
  res.send({ message: `GET. ${req.params.path1} => ${req.params.path2}` }));

// GET /?name=lalu&pwd=example
app.get('/', (req, res) =>
  res.send({ message: `name = ${req.query.name} :: pwd = ${req.query.pwd}` }));
```

| | Comes from | Looks like |
| --- | --- | --- |
| `req.params` | the path itself | `/contact/admin` |
| `req.query` | after the question mark | `/?name=lalu` |
| `req.body` | the request body, needs `express.json()` | `{ "name": "lalu" }` |

> [!warning] Never put a password in a query string
> Query strings land in server logs, browser history and proxy logs. Credentials go in the body of a POST over HTTPS.

---

## A full CRUD API

```js
const express = require('express');
const app = express();
app.use(express.json());          // parse JSON bodies

let todos = [
  { id: 1, title: 'Learn Node.js', completed: false },
  { id: 2, title: 'Build a RESTful API', completed: false },
];

// list
app.get('/todos', (req, res) => res.json(todos));

// read one
app.get('/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).json({ error: 'Todo not found' });
  res.json(todo);
});

// create
app.post('/todos', (req, res) => {
  const { title, completed } = req.body;
  if (!title) return res.status(400).json({ error: 'Title is required' });

  const newTodo = { id: todos.length + 1, title, completed: completed || false };
  todos.push(newTodo);
  res.status(201).json(newTodo);
});

app.listen(3000);
```

The status codes are the part interviewers check: `200` for a read, `201` for something created, `400` when the client sent bad input, `404` when the thing does not exist.

> [!warning] id from array length breaks
> `todos.length + 1` repeats an id as soon as anything is deleted. Fine for a demo, wrong in anything real, where the database assigns the id.

---

## In memory cache

```js
const cache = require('memory-cache');

cache.put('foo', 'bar');
console.log(cache.get('foo'));
```

Useful for one process. Useless behind a load balancer, because each instance has its own copy and they disagree. That is the point where you move to Redis.

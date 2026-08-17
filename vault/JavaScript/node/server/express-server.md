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

Declaration order matters here, so the specific routes come before the wildcards.

```js
// GET /?name=lalu&pwd=example
app.get('/', (req, res, next) =>
  res.send({ message: `name = ${req.query.name} :: pwd = ${req.query.pwd}` }));

app.get('/about', (req, res) => res.send({ message: 'GET. ABOUT' }));

// GET /contact
app.get('/:path', (req, res) => res.send({ message: `GET. ${req.params.path}` }));

// GET /contact/admin
app.get('/:path1/:path2', (req, res) =>
  res.send({ message: `GET. ${req.params.path1} => ${req.params.path2}` }));
```

Put `/:path` above `/about` and `/about` becomes unreachable. `/:path` matches it first. Express stops at the first match.

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

// update
app.put('/todos/:id', (req, res) => {
  const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (todoIndex === -1) return res.status(404).json({ error: 'Todo not found' });

  const { title, completed } = req.body;
  if (!title) return res.status(400).json({ error: 'Title is required' });

  todos[todoIndex] = {
    id: todos[todoIndex].id,
    title,
    completed: completed || todos[todoIndex].completed,
  };
  res.json(todos[todoIndex]);
});

// delete
app.delete('/todos/:id', (req, res) => {
  const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (todoIndex === -1) return res.status(404).json({ error: 'Todo not found' });

  todos.splice(todoIndex, 1);
  res.sendStatus(204);
});

app.listen(3000);
```

The status codes are the part interviewers check.

| Code | Means | Used by |
| --- | --- | --- |
| `200` | here is your answer | list, read one, update |
| `201` | created, and here it is | create |
| `204` | done, and there is nothing to send back | delete |
| `400` | the client sent bad input | create and update, when the title is missing |
| `404` | the thing does not exist | read one, update, delete |

`res.sendStatus(204)` sends the code with no body, which is the right answer for a delete. Sending `200` with an empty object instead is the usual slip.

Note that `find` returns the item while `findIndex` returns its position. Update and delete both need the position, since they have to write back into the array.

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

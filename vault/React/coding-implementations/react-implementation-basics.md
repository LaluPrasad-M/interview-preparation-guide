# React Implementations, Basic Hooks

> [!tldr]
> Five foundational React components covering useState, useEffect, handling arrays, async cleanup, and the Context API.

Part of [[coding-implementations]].

---

## 1. Counter

**What it tests:** `useState`, event handling, and functional updates.
The count cannot drop below 0.

```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  const increment = () => {
    setCount(prev => prev + 1);
  };

  const decrement = () => {
    setCount(prev => Math.max(prev - 1, 0));
  };

  const reset = () => {
    setCount(0);
  };

  return (
    <>
      <h2>{count}</h2>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
      <button onClick={reset}>Reset</button>
    </>
  );
}
```

> [!tip]
> Functional updates guarantee the latest state: `setCount(prev => prev + 1)` beats storing `count` and using it inside the handler.

---

## 2. API fetch, very common

**What it tests:** `useEffect`, async handling, and managing error and loading states.

```jsx
import { useEffect, useState } from "react";

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    try {
      setLoading(true);
      const response = await fetch("/api/users");
      if (!response.ok) throw new Error("Failed to fetch");

      const data = await response.json();
      setUsers(data);
    } catch (err) {
      setError(err.message);
    } finally {
      // Ensures loading stops regardless of success or failure
      setLoading(false);
    }
  }

  if (loading) return <p>Loading...</p>;
  if (error) return <p>{error}</p>;

  return (
    <>
      {users.map(user => (
        <div key={user.id}>{user.name}</div>
      ))}
    </>
  );
}
```

> [!tip]
> The `finally` block runs on success or failure, so loading stops no matter what.

---

## 3. Todo application

**What it tests:** managing arrays in state, immutability, unique keys, and controlled inputs.

```jsx
import { useState } from "react";

function TodoApp() {
  const [todos, setTodos] = useState([]);
  const [text, setText] = useState("");

  const addTodo = () => {
    if (!text.trim()) return;
    setTodos(prev => [
      ...prev,
      { id: Date.now(), text, completed: false }
    ]);
    setText("");
  };

  const deleteTodo = (id) => {
    setTodos(prev => prev.filter(todo => todo.id !== id));
  };

  const toggleTodo = (id) => {
    setTodos(prev =>
      prev.map(todo =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  };

  return (
    <>
      <input value={text} onChange={(e) => setText(e.target.value)} />
      <button onClick={addTodo}>Add</button>
      {todos.map(todo => (
        <div key={todo.id}>
          <span style={{ textDecoration: todo.completed ? "line-through" : "none" }}>
            {todo.text}
          </span>
          <button onClick={() => toggleTodo(todo.id)}>Toggle</button>
          <button onClick={() => deleteTodo(todo.id)}>Delete</button>
        </div>
      ))}
    </>
  );
}
```

> [!tip]
> Spread the array and map over it: never mutate state directly.
> Each todo gets a stable `key={todo.id}` so React tracks which is which.

---

## 4. Debounced search

**What it tests:** `useEffect`, cleanup functions, and debouncing.

```jsx
import { useEffect, useState } from "react";

function Search() {
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(query);
    }, 500);

    // Cleanup clears the timer on every keystroke
    return () => clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    if (!debouncedQuery) return;
    // Triggers only after 500ms of inactivity
    console.log("API Call:", debouncedQuery);
  }, [debouncedQuery]);

  return (
    <input value={query} onChange={(e) => setQuery(e.target.value)} />
  );
}
```

> [!warning]
> The cleanup function runs on every keystroke and clears the old timer.
> That is how debouncing works: only the last timer fires.

---

## 5. Theme toggle with Context

**What it tests:** the Context API and avoiding prop drilling.

```jsx
import { createContext, useContext, useState } from "react";

const ThemeContext = createContext();

function ThemeProvider({ children }) {
  const [theme, setTheme] = useState("light");

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

function ThemeButton() {
  const { theme, setTheme } = useContext(ThemeContext);

  return (
    <button onClick={() => setTheme(theme === "light" ? "dark" : "light")}>
      {theme}
    </button>
  );
}
```

> [!tip]
> Context avoids passing props through layers that do not need them.
> Create the context, wrap the tree with Provider, then call `useContext` where you need the value.

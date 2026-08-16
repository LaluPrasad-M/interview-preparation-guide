# React Coding Implementations

> [!tldr]
> The ten components interviewers actually ask you to write live. Each one tests a specific hook or a specific trap.

---

## 1. Counter

Tests `useState`, event handling and functional updates. The count cannot drop below 0.

```js
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

---

## 2. API fetch, very common

Tests `useEffect`, async handling, and managing error and loading states.

```js
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

---

## 3. Todo application

Tests managing arrays in state, immutability, unique keys and controlled inputs.

```js
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

---

## 4. Debounced search

Tests `useEffect`, cleanup functions and debouncing.

```js
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

---

## 5. Theme toggle with Context

Tests the Context API and avoiding prop drilling.

```js
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

---

## 6. Search filter, and the derived state insight

Tests computing derived state.

> [!warning] The insight interviewers look for
> Do not store the filtered list in a state variable. Derived state should be computed during render.

```js
import { useState } from "react";

function UserSearch() {
  const users = ["Rahul", "Aman", "Neha", "John"];
  const [query, setQuery] = useState("");

  // Calculated on the fly, no extra state needed
  const filteredUsers = users.filter(user =>
    user.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      {filteredUsers.map(user => (
        <div key={user}>{user}</div>
      ))}
    </>
  );
}
```

---

## 7. Form validation

Disable submit until the email is valid and the password is at least 6 characters.

```js
import { useState } from "react";

function Login() {
  const [form, setForm] = useState({ email: "", password: "" });

  const isValid = form.email.includes("@") && form.password.length >= 6;

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  return (
    <>
      <input name="email" value={form.email} onChange={handleChange} />
      <input name="password" value={form.password} onChange={handleChange} />
      <button disabled={!isValid}>Submit</button>
    </>
  );
}
```

---

## 8. Custom hook, window width

A reusable hook tracking window dimensions.

```js
import { useEffect, useState } from "react";

function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);

  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener("resize", handleResize);

    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return width;
}

function App() {
  const width = useWindowWidth();
  return <h1>{width}</h1>;
}
```

---

## 9. Toggle

Tests conditional rendering and boolean state.

```js
import { useState } from "react";

function Toggle() {
  const [show, setShow] = useState(false);

  return (
    <>
      <button onClick={() => setShow(prev => !prev)}>Toggle</button>
      {show && <p>Hello World</p>}
    </>
  );
}
```

---

## 10. Modal

Tests state management and conditional rendering.

```js
import { useState } from "react";

function ModalExample() {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button onClick={() => setOpen(true)}>Open</button>
      {open && (
        <div>
          <h2>Modal Content</h2>
          <button onClick={() => setOpen(false)}>Close</button>
        </div>
      )}
    </>
  );
}
```

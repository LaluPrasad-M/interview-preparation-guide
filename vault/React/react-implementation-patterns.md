# React Implementations, Patterns and Advanced

> [!tldr]
> Five advanced React patterns covering derived state, form validation, custom hooks, conditional rendering, and state-driven UI.

Part of [[coding-implementations]].

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

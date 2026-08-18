# React Implementations, Patterns and Advanced

> [!tldr]
> Five advanced React patterns covering derived state, form validation, custom hooks, conditional rendering, and state-driven UI.

Part of [[coding-implementations]].

---

## 6. Search filter, and the derived state insight

**What it tests:** computing derived state.

> [!warning]
> Do not store the filtered list in state.
> Derived state should be computed during render, not stored separately.

```jsx
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

> [!tip]
> Compute the filtered list inline: `users.filter(...)`.
> No extra state variable needed.

---

## 7. Form validation

**What it tests:** disabling submit until form conditions are met.
Email must be valid and password must be at least 6 characters.

```jsx
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

> [!tip]
> Derived state: compute `isValid` inline.
> The button state depends on form state, but they share no extra state variable.

---

## 8. Custom hook, window width

**What it tests:** building a reusable hook that tracks window dimensions.

```jsx
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

> [!tip]
> Extract the hook logic into a custom hook: `useWindowWidth()` returns a value you can call anywhere.
> The component uses the hook without knowing the details inside.

---

## 9. Toggle

**What it tests:** conditional rendering and boolean state.

```jsx
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

> [!tip]
> Functional update with a boolean: `setShow(prev => !prev)`.
> Conditional rendering in JSX: `{show && <p>...</p>}`.

---

## 10. Modal

**What it tests:** state management and conditional rendering.

```jsx
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

> [!tip]
> State controls visibility: `{open && <div>...</div>}`.
> No need for a separate rendered/hidden state, just show or hide based on the boolean.

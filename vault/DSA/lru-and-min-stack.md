# LRU Cache and Min Stack

> [!tldr]
> Two data structure designs that show up constantly. LRU is a hash map plus a doubly linked list; Min Stack is a second stack carrying the running minimum.

---

## LRU Cache

### 1. Hash map plus doubly linked list

To get O(1) for both `get()` and `put()` you must use:

- a hash map, for O(1) lookup
- a doubly linked list, for O(1) insert and delete

This combination is non negotiable.

### 2. The list maintains recency order

```text
HEAD -> Most Recently Used (MRU)
TAIL -> Least Recently Used (LRU)
```

Whenever a key is used, in `get` or `put`, move that key's node to the head. That is the heart of LRU.

### 3. Removing the LRU means removing `tail.prev`

Never remove the dummy tail. The correct LRU node is `this.tail.prev`, because the layout is:

```text
HEAD(dummy) <-> ...nodes... <-> LRU <-> TAIL(dummy)
```

### 4. Always use dummy head and dummy tail

This avoids messy edge cases. With dummy nodes, insert is always safe, remove is always safe, and you never need a `if (head == null)` check. This is why LRU becomes clean.

### 5. `get(key)` does two things

Return the value, and move the node to MRU:

```text
remove(node)
insertAtHead(node)
```

Just returning the value is not enough.

### 6. `put(key, value)` has three cases

| Case | Action |
| --- | --- |
| Key exists | update and move to MRU |
| Key does not exist and the cache is not full | insert at MRU |
| Key does not exist and the cache is full | evict the LRU, then insert |

### 7. The node must store both key and value

When evicting from the linked list, you need the key to delete from the hash map:

```js
this.map.delete(node.key)
```

If the node did not store the key you could not delete it properly.

### 8. Always remove a node before reinserting

Do not try to move it without removing first. The safe sequence is always:

```text
remove(node)
insertAtHead(node)
```

This prevents broken pointers.

### The summary to print in your mind

Use a Map for O(1) access. Use a doubly linked list for O(1) updates. HEAD is MRU, TAIL is LRU. On `get()`, move to head. On `put()`, update or insert or evict. LRU is `tail.prev`. Always remove before insert. The node stores both key and value.

### With a TTL

A production flavour of the same structure, with lazy expiry on read and capacity based eviction.

```js
class LRUCache {
  constructor(capacity, ttlMs) {
    this.capacity = capacity;
    this.ttlMs = ttlMs;
    this.cache = new Map();
  }

  get(key) {
    if (!this.cache.has(key)) return null;

    const entry = this.cache.get(key);
    if (Date.now() > entry.expiry) {
      this.cache.delete(key);
      return null;
    }

    this.cache.delete(key);
    this.cache.set(key, entry);
    return entry.value;
  }

  put(key, value) {
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    if (this.cache.size >= this.capacity) {
      const lruKey = this.cache.keys().next().value;
      this.cache.delete(lruKey);
    }

    this.cache.set(key, {
      value,
      expiry: Date.now() + this.ttlMs
    });
  }
}
```

This version leans on the fact that a JavaScript `Map` maintains insertion order, so deleting and re setting a key moves it to the end.

---

## Min Stack

Three approaches exist. The first uses two stacks, the second is a space optimised single stack with a trick, and the third is a plain single stack.

### The space optimised single stack

Store values in the stack as follows.

Normally push the value. If the new value is at or below the current minimum, push the old minimum first, update `minEle`, then push the new value.

For pop: if the popped value equals the current minimum, pop it, and the top now holds the old minimum, so restore `minEle` from that stored value.

### The two stack version, which is what to write in an interview

```js
var MinStack = function() {
    this.mainStack = [];
    this.minStack = [];
};

/**
 * @param {number} val
 * @return {void}
 */
MinStack.prototype.push = function(val) {
    this.mainStack.push(val);

    if (this.minStack.length === 0) {
        this.minStack.push(val);
    } else {
        // push the same min if val is bigger
        // push the val if val is smaller
        this.minStack.push(Math.min(val, this.minStack[this.minStack.length - 1]));
    }
};

/**
 * @return {void}
 */
MinStack.prototype.pop = function() {
    this.mainStack.pop();
    this.minStack.pop();
};

/**
 * @return {number}
 */
MinStack.prototype.top = function() {
    return this.mainStack[this.mainStack.length - 1]
};

/**
 * @return {number}
 */
MinStack.prototype.getMin = function() {
    return this.minStack[this.minStack.length - 1];
};
```

Both stacks stay the same height, so `pop` is symmetric and `getMin` is a constant time read.

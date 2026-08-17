# Machine Coding Problem List

> [!tldr]
> Seven levels, ordered. Practise level 1 before level 2. P0 means you fail the round without it, P1 is the most frequently asked, P2 and P3 are niche or company specific.

---

## Level 1: the bedrock, data structures and memory

Do not touch a system design or OOP question until you can build these from memory. They prove you understand memory allocation, pointers and hashing.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P0 | Design a HashMap | implement put, get and remove without built in map libraries | array of linked lists (chaining). Hash the key and modulo it by array length, `hash(key) % length`, to find the index. If multiple keys collide, store them as a linked list in that bucket |
| P0 | Design a HashSet | implement add, contains and remove for unique elements | a HashMap with dummy values. Store elements as keys and use a static dummy constant as the value. Or implement the same array of linked lists directly |
| P0 | LRU Cache | evict the least recently used item, the precursor to LFU | hash map plus doubly linked list. The map gives constant time lookup to the exact node, the list tracks recency. Moving a node to the head on every read or write keeps the tail as the LRU item |
| P1 | LFU Cache | evict the least frequently used item, tie break to LRU | two maps plus a min frequency tracker. Map 1 stores key to value, map 2 stores frequency to a doubly linked list of keys. An integer tracks the current minimum frequency to know which list to evict from |

See [[lru-and-min-stack]] for a full LRU implementation.

---

## Level 2: core object oriented modelling

These test your ability to use SOLID, design patterns, and handle basic state.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P0 | Tic-Tac-Toe or a board game | a scalable n by n board game tracking turns and win conditions | strategy pattern plus a constant time win check. Do not traverse the board. Keep arrays for `rows[]`, `cols[]`, `diagonal` and `antiDiagonal`. Player 1 adds 1, player 2 subtracts 1. If any value hits `+n` or `-n`, someone won |
| P0 | Vending machine or elevator | complex sequential rules and transitions based on user input | the state pattern. Avoid massive switch statements. Create a `State` interface with concrete classes like `IdleState`, `HasCoinState`, `DispensingState`. Each state handles its own logic and dictates the next transition |
| P1 | Parking lot system | multiple levels, different vehicle sizes, dynamic availability | strategy pattern plus a min heap. Use a min heap of available spots ordered by distance to the entrance for fast retrieval. Use strategy to plug in different pricing models, flat rate against hourly |
| P1 | Movie booking | multiple theatres and shows, and preventing two users booking the same seat | optimistic or pessimistic locking plus a state machine. Model the seat with states `AVAILABLE`, `LOCKED`, `BOOKED`. Use a distributed lock or DB transaction isolation when a user selects a seat, and a background timer to revert to `AVAILABLE` if payment fails after 10 minutes |

---

## Level 3: API, infrastructure and frameworks

How do you build the tools other developers use?

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P0 | Logger library | a logging framework supporting INFO, DEBUG, ERROR and different outputs | chain of responsibility plus observer. The core logger uses chain of responsibility to process log levels, and the observer pattern for appenders such as `ConsoleAppender` and `FileAppender`. If the level matches, notify the appenders to write |
| P0 | Event emitter, pub/sub | `subscribe(topic)`, `emit(topic)`, `unsubscribe()` | a map of sets. `Map<Topic, Set>`. The hardest part is unsubscribe: return an object with a `release()` method from `subscribe` so the user can cancel in constant time |
| P1 | Rate limiter | allow max N requests per M seconds | token bucket or sliding window log. Token bucket stores `[tokens_left, last_updated_timestamp]`. Sliding window uses a queue of timestamps, popping ones that fall outside the window |
| P1 | Hit counter | count hits received in the past 5 minutes | a circular array, a ring buffer. Two arrays of size 300, `times[300]` and `hits[300]`. Index is `timestamp % 300`. If `times[index]` is not the current timestamp, reset the hit count to 1 and update the time, otherwise increment |
| P1 | Notification system | send alerts by SMS, email or push, dynamically based on preference | factory plus strategy. A `NotificationFactory` reads the user's settings and instantiates the correct `NotificationStrategy`, for example `SMSStrategy`. Adding WhatsApp or Slack later becomes trivial |

---

## Level 4: text processing and routing

This is heavily algorithmic. It tests your ability to organise string data efficiently.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P1 | Trie, prefix tree | autocomplete and typeahead | nested hash maps plus an `isWord` flag. Each node is `{ children: Map, isWord: boolean }`. To find all words for a prefix, traverse to the end of the prefix then run DFS collecting branches where `isWord` is true |
| P1 | HTTP router | route URLs to handlers, supporting path variables like `/users/:id/posts` | a radix tree, a compact prefix tree. Each node is a path segment. Standard children are exact string matches, and a special wildcard child handles variables like `:id`, extracting the value into a map before passing to the handler |
| P1 | Text editor | a moving cursor with insert, delete, left and right | two stacks, the gap buffer. `leftStack` holds everything left of the cursor, `rightStack` everything right. `insert(char)` pushes to `leftStack`. `moveLeft()` pops from `leftStack` and pushes to `rightStack`. All operations are constant time |
| P2 | Autocomplete system | a search bar returning the top 3 historical searches for a prefix by frequency | trie plus min heap cache. A standard trie, but every node maintains a min heap of size 3 with the top historical phrases passing through it. Trades space for very fast reads |

---

## Level 5: concurrency and multithreading

This is mandatory if you code in Java, C++, Go or Rust.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P1 | Bounded blocking queue | producer and consumer, where push blocks if full and pop blocks if empty | mutex lock plus condition variables. You need an array, a lock, and two conditions, `notFull` and `notEmpty`. Push waits on `notFull` and signals `notEmpty`. Pop does the reverse |
| P1 | Task scheduler | run `setTimeout(callback, delay)` natively, in chronological order | min heap plus an event loop. Store tasks in a min heap sorted by `execute_at`. A background loop checks the heap top, and pops and runs when `current_time >= top.execute_at` |
| P1 | Thread pool | an executor that takes tasks and distributes them across K worker threads | array of threads plus a blocking queue. Initialise K threads in a `while(true)` loop constantly attempting to pop from a shared blocking queue. Submitting a task puts it in the queue, waking exactly one idle thread |
| P2 | DB connection pool | reuse expensive database connections rather than creating one per request | object pool pattern plus a blocking queue. Maintain a fixed size queue of initialised connection objects. `acquire()` blocks if none are available, `release()` returns it and signals waiting threads |

See [[singleton]] for a worked connection pool.

---

## Level 6: advanced in memory and storage algorithms

This is often asked at database companies or high frequency trading firms.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P2 | KV store with transactions | `get`, `set`, `begin()`, `commit()`, `rollback()` | a stack of hash maps. `begin()` pushes a new empty map onto the stack. Reads check top to bottom. `commit()` merges the top map into the one below. `rollback()` pops and deletes the top map |
| P2 | Snapshot array | call `snap()` to save state, and `get(index, snap_id)` to look up history | an array of binary searchable maps. Instead of copying the whole array on `snap()`, each index holds a list of `[snap_id, value]`. Binary search finds the closest `snap_id` when reading |
| P2 | In memory file system | `mkdir`, `ls`, `addContentToFile`, `readContentFromFile` | the composite pattern, effectively a trie. A directory node holds a hash map of names pointing to either other directory nodes or file nodes. Treat paths like `/a/b/c` exactly like words in a trie |

---

## Level 7: distributed system primitives

These blur the line between high level system design and machine coding.

| Priority | Problem | The concept | The senior mental trigger |
| --- | --- | --- | --- |
| P1 | Splitwise, debts | split bills equally, by exact amounts, or by percentages, and simplify debts | graph plus strategy pattern. Model balances as a directed graph and use strategy for the splitting logic. To simplify debts, use a greedy algorithm with a max heap for debtors and creditors, matching whoever owes most with whoever is owed most |
| P2 | URL shortener | convert a long URL to a short one | Base62 encoding plus an auto increment ID. Use a global database counter, convert the base 10 ID to base 62 over `[a-zA-Z0-9]`, and store the mapping |
| P2 | Load balancer | distribute traffic across a pool of healthy servers | strategy pattern plus a background heartbeat. Maintain a list of active servers updated by a background thread pinging `/health`. Implement routing strategies: round robin using an atomic counter modulo N, or least connections using a min heap |
| P2 | ID generator | globally unique, sortable IDs without a single database | Snowflake ID, bitwise maths. A 64 bit integer combining time and location: 41 bits for an epoch timestamp which keeps it sortable, 10 bits for machine or datacenter ID, and 12 bits for a sequence number to prevent collisions in the same millisecond |
| P2 | Leaderboard | millions of players, constant score updates, fetch top 10 and player rank | skip list or TreeMap plus a hash map. The hash map stores player ID to node. A skip list or self balancing BST keeps scores sorted, allowing logarithmic updates and rank lookups |
| P3 | Consistent hashing | map requests to servers so adding or removing one moves only 1/N of the keys | sorted array plus binary search. Hash the servers to integers and place them in a sorted array. Hash the incoming request, then binary search for the first server hash strictly greater than the request hash |
| P3 | Proximity server | find restaurants or drivers within a geographic radius | quadtree or geohash. A quadtree recursively divides a 2D map into 4 quadrants, giving logarithmic spatial search. Geohashing interleaves latitude and longitude bits into a string, so locations sharing a prefix are physically close |

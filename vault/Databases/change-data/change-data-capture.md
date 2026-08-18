# Change Data Capture

> [!tldr]
> CDC turns your database into a live event broadcaster by tailing the transaction log, instead of downstream systems repeatedly asking "did anything change?"

---

## The old way, database polling

Downstream systems periodically query the database asking whether anything changed.

Three major drawbacks:

**Resource waste.** It consumes significant database CPU and I/O running repetitive queries.

**Data loss.** If a record is created and deleted between polling intervals, downstream systems never know it existed.

**High latency.** Your search results and analytics are always out of date by the length of the polling window, for example 5 minutes.

---

## The CDC way

Instead of downstream systems asking for updates, the database instantly announces changes as they happen: "user 123 just changed their name to Rahul".

---

## How it works, step by step

```text
+-----------------+       +-----------------+       +-----------------+
|   App Update    | ----> | Transaction Log | ----> |    CDC Tool     |
| (Postgres/MySQL)|       |  (WAL / Binlog) |       |   (Debezium)    |
+-----------------+       +-----------------+       +--------+--------+
                                                             |
                                                             v
+-----------------+       +-----------------+       +-----------------+
| Search Engine / | <---- |  Message Queue  | <-----+ Publishes Event |
| Data Warehouse  |       | (Apache Kafka)  |       |                 |
+-----------------+       +-----------------+       +-----------------+
```

1. **The application makes a change.** A user updates their profile picture, and the backend sends a standard `UPDATE` to the primary database.

2. **The database writes to its transaction log.** Before updating table data on disk, the database writes the change to an internal append only log, the [[write-ahead-log|write ahead log]] in Postgres or the binlog in MySQL. Databases already do this natively for crash recovery.

3. **The CDC tool reads the log.** A tool such as Debezium tails the transaction log continuously. It never queries the tables directly, it just parses log entries like `Row 45 updated: previous_value='old_pic.jpg', new_value='new_pic.jpg'`.

4. **Broadcasting via a message broker.** The CDC tool translates the log entry into a structured event and streams it to Kafka, which acts as a high throughput distribution hub.

5. **Downstream systems consume the event.** Any subscriber to the Kafka topic, such as your search index, Redis cache or data warehouse, instantly receives the change and updates its local state.

---

## Key advantages

| Feature | Polling | Change Data Capture |
| --- | --- | --- |
| Latency | high, minutes | sub second, milliseconds |
| Database load | heavy, periodic `SELECT` queries | near zero, passive log tailing |
| Data integrity | can miss intermediate updates and deletions | captures every state transition chronologically |

---

## Handling outages: bookmarks and recovery

The entire CDC ecosystem relies on something like a physical bookmark in a book. In the database world this is called an offset, or a log sequence number.

Every line written to the transaction log gets a unique sequential number. As the CDC tool reads the log it constantly saves its current bookmark position, making outage recovery a built in feature rather than a crisis.

### The CDC tool goes offline

The server running Debezium loses power for an hour. The primary database keeps serving user traffic and writing new changes to its log, unaffected.

When power is restored, the CDC tool boots, checks its internal storage for the last saved bookmark, for example offset 50,421, and asks the database for everything from 50,422 onward.

It rapidly reads the accumulated logs, publishes them to Kafka in exact chronological order, and catches up to real time with zero data loss.

### Kafka goes offline

The CDC tool stays operational but has nowhere to send messages.

Because the CDC tool demands strict acknowledgement from Kafka before advancing its bookmark, it pauses reading the database log entirely.

Once Kafka is back, the tool delivers the blocked message, receives confirmation, updates its bookmark, and resumes tailing.

---

## The major risk: log truncation

Permanent data loss occurs in only one specific scenario.

**The problem.** Databases do not retain transaction logs indefinitely. To stop disks filling up, they purge old logs after a set duration, for example 24 hours, or above a maximum size, for example 50 GB.

**The failure.** If your CDC tool or broker goes down for 48 hours but the database deletes logs after 24 hours, the unread logs are purged before the tool recovers.

**The result.** When the CDC tool comes back and requests offset 50,422, the database no longer has it.

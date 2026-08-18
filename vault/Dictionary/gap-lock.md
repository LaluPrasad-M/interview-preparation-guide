# Gap Lock

> [!tldr]
> A lock on the empty space between two index entries rather than on any existing row, so nobody can insert a new row into that space until the transaction finishes.

MySQL's InnoDB engine uses these to stop a phantom read, which is when you run the same range query twice inside one transaction and the second run returns a row that was not there before.

> [!example]- Where the gaps are
> A table has rows with `age` values 20, 25 and 30, indexed on `age`.
>
> ```sql
> -- session A, inside a transaction at REPEATABLE READ
> SELECT * FROM users WHERE age > 20 FOR UPDATE;
> ```
>
> InnoDB locks the rows 25 and 30, and also the gaps: between 20 and 25, between 25 and 30, and everything above 30.
>
> ```sql
> -- session B
> INSERT INTO users (age) VALUES (27);   -- blocks, waiting on session A
> ```
>
> Row 27 does not exist and never did, and session B is still stuck, because the space where it would go is locked.

| Lock type     | What it holds                            | Stops                                           |
| ------------- | ---------------------------------------- | ----------------------------------------------- |
| Record lock   | one existing index entry                 | two writers changing the same row               |
| Gap lock      | the space between entries, no row needed | new rows appearing inside a range               |
| Next-key lock | one record plus the gap before it        | both of the above, and this is InnoDB's default |

> [!warning] This is where surprising deadlocks come from
> An insert that blocks behind a slow range query it has nothing to do with looks impossible until you know gaps get locked. Two transactions inserting into the same gap in different orders is another common one.

Isolation level decides whether you get them at all. `REPEATABLE READ` uses gap locks; `READ COMMITTED` drops them, which is why some teams run at the lower level and accept phantom reads instead.

**Shows up in:** [[read-lock-contention]].

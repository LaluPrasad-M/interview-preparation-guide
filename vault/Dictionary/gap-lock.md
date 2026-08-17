# Gap Lock

> [!tldr]
> A lock on the empty space between index rows, not on a row itself, so nothing can be inserted into that gap until the transaction commits.

Under REPEATABLE READ, a range query like `WHERE age > 20` locks the gaps between matching rows to stop phantom reads. Nothing needs to already exist there for the lock to apply.

That is why an unrelated insert can block behind a slow range query that never touches the row being inserted.

**Shows up in:** [[read-lock-contention]].

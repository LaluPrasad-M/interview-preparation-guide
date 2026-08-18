# Write Ahead Log (WAL)

> [!tldr]
> The database writes down what it is about to do before it does it, so a crash mid write can be replayed and finished.

Every change goes into an append only file first, then into the actual data pages later. Appending to the end of a file is fast; updating pages scattered across a disk is not.

On restart the database reads the log and redoes anything that did not land. That is why a crash loses seconds of work rather than the whole table.

**Shows up in:** [[write-path-basics]], [[replication]], [[change-data-capture]].

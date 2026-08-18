# Write Amplification

> [!tldr]
> One logical write turns into many physical writes, because every index, replica and storage bookkeeping structure has to be updated too.

Inserting one row also updates every index on that table, and each of those generates its own log entries. A random UUID primary key reshuffles a B-tree on every insert; an embedded document rewritten to add one field rewrites the whole document.

The pattern is the same wherever a small logical change fans out physically, and it is why high write systems avoid random keys and heavy embedding.

**Shows up in:** [[write-path-basics]], [[distributed-id-generation]], [[embedding-and-referencing]].

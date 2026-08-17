# Bloom Filter

> [!tldr]
> A probabilistic structure that answers "definitely not present" or "maybe present," never a false negative, so it can skip a database lookup entirely.

Checked before a cache miss falls through to the database, so a flood of requests for keys that never existed does not become a flood of database queries.

It can wrongly say maybe when the real answer is no, a false positive, but it never says no when the real answer is yes.

**Shows up in:** [[caching-problems]].

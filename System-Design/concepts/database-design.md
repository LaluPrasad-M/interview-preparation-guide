# Database Design

> [!tldr]
> The part you cannot easily undo. Code ships again tomorrow. A bad schema follows you for years, and lost data never comes back.

---

## What a good design gives you

| What you get | How |
| --- | --- |
| **Fast queries** | Indexes so lookups do not read the whole table, and a schema shaped like the questions you actually ask. |
| **Survives failure** | Replication keeps copies on other machines. One leader takes writes, followers copy it, and a follower is promoted if the leader dies. |
| **Trustworthy data** | ACID transactions mean a group of changes all happen or none do, so money never leaves one account without arriving in the other. Event sourcing keeps the list of changes, not just the final state, which gives you an audit trail. |

> [!warning] The N plus one trap
> You fetch a list of one hundred rows, then run one hundred more queries to fill in their details. It looks fine on your laptop with three rows and falls over in production.

---

## What a bad one costs

**Slow queries.** Full table scans, missing indexes, joins written without thinking about which side is large.

**A ceiling on growth.** One node holding everything, and no plan for splitting the data when it no longer fits.

**Real data loss.** No backups, or backups nobody has ever tried to restore.

---

## Three decisions worth remembering

**SQL or NoSQL.**

| Store | Choose it when |
| --- | --- |
| **SQL** | the data has a clear shape, relationships matter, you want joins and transactions |
| **NoSQL** | the shape varies, or throughput matters more than strict structure |

**Sharding or replication.** Constantly confused, so worth separating.

| Technique | What it does | Fixes |
| --- | --- | --- |
| **Sharding** | splits one dataset across machines, each holding a slice | data too big |
| **Replication** | copies the same data to several machines | reads too many |

**Backup and recovery.** Automated backups, plus point in time recovery so you can rewind to just before someone ran the wrong statement.

> [!tip] The line worth saying out loud
> A backup you have never restored is not a backup. Practise the restore before you need it.

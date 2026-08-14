# S3 Storage Classes

> [!tldr]
> Same durability everywhere, different cost and different retrieval speed. You are choosing how quickly you need the data back, and paying accordingly.

---

## The classes

| Storage class | Use case | Durability | Availability |
| --- | --- | --- | --- |
| S3 Standard | frequently accessed data | 11 nines | 99.99% |
| S3 Intelligent-Tiering | moves data between tiers automatically | 11 nines | 99.90% |
| S3 Standard-IA | infrequent access, lower cost | 11 nines | 99.90% |
| S3 One Zone-IA | infrequent access, single availability zone | 11 nines | 99.50% |
| S3 Glacier | long term archival | 11 nines | hours to retrieve |
| S3 Glacier Deep Archive | cheapest archival | 11 nines | 12 or more hours to retrieve |

---

## How to read that table

**Durability never changes.** Every class is eleven nines. Choosing a cheaper class does not risk your data, it changes how fast and how cheaply you can read it.

**Availability does change**, and it means the chance the service can serve a request right now, not the chance the data still exists.

**One Zone-IA is the one to be careful with.** It keeps the data in a single availability zone, so the eleven nines apply to the object, and losing that zone still loses your access. Fine for data you can regenerate, wrong for the only copy of something.

**Glacier is measured in hours.** It is not slow storage, it is cold storage, and the retrieval time is the product rather than a limitation. Anything you might need inside a minute does not belong there.

**Intelligent-Tiering** is the answer when you genuinely do not know the access pattern. It watches and moves objects for you, for a small monitoring fee per object, which is worth it for large unpredictable datasets and not worth it for a handful of files.

Move objects between classes automatically with [[s3-lifecycle]].

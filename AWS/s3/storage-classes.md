# S3 Storage Classes

> [!tldr]
> All six classes quote eleven nines of durability, but One Zone-IA earns its eleven nines inside a single Availability Zone, which makes it the one class where choosing cheap genuinely risks the data.

---

## The classes

| Storage class | Use case | Durability | Availability | Retrieval |
| --- | --- | --- | --- | --- |
| S3 Standard | frequently accessed data | 11 nines | 99.99% | immediate |
| S3 Intelligent-Tiering | moves data between tiers automatically | 11 nines | 99.90% | immediate |
| S3 Standard-IA | infrequent access, lower cost | 11 nines | 99.90% | immediate |
| S3 One Zone-IA | infrequent access, single availability zone | 11 nines, within one AZ | 99.50% | immediate |
| S3 Glacier | long term archival | 11 nines | 99.99% | hours |
| S3 Glacier Deep Archive | cheapest archival | 11 nines | 99.99% | 12 or more hours |

> [!warning] Your source table put retrieval time in the availability column
> The original notes list "hours to retrieve" and "12+ hours retrieval" as the availability figures for the two Glacier classes. Those are retrieval times, and they belong in their own column, which is why it is split out above. Both Glacier classes are designed for the same 99.99% availability as Standard. Availability is the chance the service answers your request; retrieval time is how long it then takes to hand the object over.

---

## How to read that table

**Durability is eleven nines everywhere, with one asterisk.** For five of the six classes that number covers the loss of an entire Availability Zone, because the data is replicated across at least three of them.

**One Zone-IA is the exception, and it is a real one.** It stores one copy in one AZ. AWS states plainly that data in One Zone-IA is not resilient to the physical loss of that zone. So an AZ failure destroys those objects, permanently, and the eleven nines only describe the odds inside the zone that no longer exists.

That makes One Zone-IA correct for data you can regenerate, a thumbnail you can rebuild from the original, a cache, a derived dataset. It is wrong for the only copy of anything.

**Glacier is cold, not slow.** The retrieval time is the product rather than a defect. Anything you might need within a minute does not belong there.

**Intelligent-Tiering** is the answer when you genuinely do not know the access pattern. It watches and moves objects for you, for a small monitoring fee per object, which is worth it for a large unpredictable dataset and not worth it for a handful of files.

Move objects between classes automatically with [[s3-lifecycle]].

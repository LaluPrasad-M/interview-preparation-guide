# Quorum

> [!tldr]
> A write or read counts as successful once enough replicas acknowledge it, not all of them, so a few slow or dead nodes never block traffic.

With 3 replicas and a quorum of 2, one replica can lag or fail without stalling writes. This is how distributed systems trade some consistency for availability without going fully eventual.

Set read quorum plus write quorum greater than the replica count and a read is guaranteed to see the latest acknowledged write.

**Shows up in:** [[sharding-and-scale]], [[scaling-ladders]].

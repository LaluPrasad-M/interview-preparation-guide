# Amortised Analysis

> [!tldr]
> Averaging the cost of an expensive operation across many cheap ones, so the reported cost reflects the whole sequence rather than its worst single step.

A dynamic array's occasional resize and copy looks expensive in isolation, but spread across all the cheap appends that led to it, each append is still O(1) amortised.

The same idea appears outside DSA: batching writes to amortise one `fsync`, or one bulk insert to amortise per document indexing overhead.

**Shows up in:** [[write-path-basics]], [[websales-lld]].

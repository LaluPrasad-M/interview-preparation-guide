# Bloom Filter

> [!tldr]
> A tiny structure that answers only two ways, "definitely not there" or "maybe there", and is never wrong about the first one. You use it to skip a lookup you know would come back empty.

It is a row of bits plus a few hash functions. Adding a key sets a few bits. Checking a key looks at those same bits, and if any of them is still 0 the key was certainly never added.

> [!example]- Ten bits and two hash functions
> Start with 10 bits, all zero.
>
> ```text
> add("cat")     h1 -> 2, h2 -> 7      set bits 2 and 7
> check("cat")   bits 2 and 7 set      maybe present, go ask the database
> check("dog")   h1 -> 4, bit 4 is 0   definitely not present, skip the database
> check("emu")   h1 -> 2, h2 -> 7      maybe present, but "emu" was never added
> ```
>
> That last line is a false positive: bits set by `cat` made `emu` look plausible. You pay one wasted database query and get the right answer anyway.

| The filter says | Can it be wrong | What it costs you |
| --- | --- | --- |
| definitely not present | no, never | nothing, you correctly skipped a lookup |
| maybe present | yes, sometimes | one lookup you did not need |

Because the "no" is trustworthy, the filter sits in front of an expensive store. A flood of requests for user IDs that never existed gets stopped at a few bits of memory instead of turning into a flood of database reads.

> [!warning] You cannot remove a key
> Clearing the bits for one key would also clear bits shared with other keys, so a plain Bloom filter only ever grows. Removal needs a counting Bloom filter, which stores small counters instead of single bits.

More bits and more hash functions push the false positive rate down, so the real design question is how much memory you will trade for how many pointless lookups.

**Shows up in:** [[caching-problems]].

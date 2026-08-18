# Context Poisoning

> [!tldr]
> Irrelevant material sitting in a model's context window drags the answer down, even when the correct information is right there next to it.

A model has to weigh everything you gave it. Extra text is not free background, it is competing evidence, and enough of it will pull the answer towards something plausible and wrong.

> [!example]- Same question, two contexts
> **Poisoned.** You paste a whole 2000 line file to ask about one 20 line function. The file also contains three older versions of similar logic and a commented out approach that was abandoned. The model blends them and describes behaviour the live function does not have.
>
> **Clean.** You paste the function, the two helpers it calls, and the type it returns. The answer is about the code that actually runs.

| Looks helpful | What it actually does |
| --- | --- |
| the whole file, for safety | adds dead branches the model treats as real |
| the full conversation history | keeps a decision alive that you already reversed |
| every search result, ranked loosely | buries the one relevant hit among near misses |

The fix is retrieval that scopes tightly. Map the dependencies of the thing being asked about, inject only those nodes, and drop history that has been superseded rather than appending to it forever.

**Shows up in:** [[token-optimization]].

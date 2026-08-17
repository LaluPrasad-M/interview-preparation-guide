# Context Poisoning

> [!tldr]
> Irrelevant material sitting in a model's context window confuses it into a worse answer, even when the correct information is also present.

More context is not automatically better context. Injecting a whole file when only one function is relevant, or a whole conversation history when only the last decision matters, gives the model noise to weigh against the signal.

The fix is retrieval that scopes tightly: map dependencies and inject only the specific nodes needed to answer the prompt, instead of dumping everything nearby.

**Shows up in:** [[token-optimization]].

# Token Optimization

> [!tldr]
> Four techniques attacking token bloat at four different stages of the request lifecycle: mapping, input compression, output compression, and code diffing.

---

## The stack at a glance

| Technique | Stage | What it does |
| --- | --- | --- |
| Graphify | pre retrieval and mapping | stores a map of the entire repo before searching |
| Headroom | input and context compression | compresses tool outputs and file contents |
| Caveman | semantic and output compression | strips conversational padding |
| PonyTail | action and code optimisation | focuses on reuse and minimal changes |

---

## Graphify, pre retrieval and mapping

Instead of dumping raw flat code files into a context window, generate an abstract syntax tree or knowledge graph of the repository before executing a search.

By mapping dependencies, imports and function signatures, the system injects only the specific nodes and clusters required to answer the prompt. That prevents context poisoning, where irrelevant code confuses the model.

---

## Headroom, input and context compression

It is an optimisation proxy layer, often integrated with a gateway. It intercepts what the model is about to read, such as massive tool outputs, 500 line error logs or dense retrieval payloads, and aggressively compresses them before forwarding.

It ensures the model has the headroom it needs to reason, without drowning in verbose system logs.

---

## Caveman, semantic and output compression

It is a prompt and memory compression methodology that strips predictable grammar, conversational padding and formatting fluff.

Instead of a model outputting "Certainly! Here is the function you requested to filter users", Caveman enforces strict primitive constraints: "Filter function. Input: User[]. Output: User[]. No explanation".

This can cut memory file sizes and output token costs by over 80 percent, without losing any of the facts.

---

## PonyTail, action and code optimisation

This focuses on output token efficiency during code generation.

Models have a bad habit of reinventing the wheel, installing redundant packages or rewriting a 200 line file to change one variable. PonyTail style tooling forces minimal structural changes, such as unified diffs or targeted patches, and reuse of existing codebase utilities.

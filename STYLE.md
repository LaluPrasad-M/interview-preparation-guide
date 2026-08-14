# Style

How notes should explain things: the quality of the writing itself.

Starting with two rules. More get added as we find them.

## Rule 1: a ten-year-old should follow it

Write every explanation so a smart ten-year-old could read it and get the idea. Short
sentences. Everyday words. No showing off.

**Why this matters more than it sounds:** in an interview you say these things out loud,
under pressure, to someone who is judging whether you understand them. A note written in
dense textbook language is a note you can recite but not explain. If you cannot say it
simply, you do not know it yet, and the note is the place to find that out rather than the
interview.

### What to do

- One idea per sentence. If a sentence has two "and"s, split it.
- Pick the everyday word. *Runs out of space*, not *exhausts capacity*. *Slow*, not
  *computationally expensive*.
- Say the concrete thing first, the general rule second. "You check the first and last
  item, then move inward" before "two-pointer traversal".
- Cut filler. *Basically*, *essentially*, *it should be noted that*: delete them.
- Read it out loud. If you stumble or run out of breath, rewrite that sentence.

### This is not dumbing down

The precise terms stay: *amortised*, *idempotent*, *backpressure*. You need them, because
interviewers use them and you should too. The rule is about the **explaining**. Define the
term in plain words the first time it shows up, then use it freely from there.

Simple language, precise vocabulary. Both.

### Examples

**Complexity**

Too dense:

> Amortised O(1) insertion is achieved via geometric reallocation, mitigating the linear
> cost of array growth.

Rewritten:

> Adding to a dynamic array is usually instant. Now and then the array is full, so it makes
> a bigger one, twice the size, and copies everything across. That copy is slow. But it
> happens rarely enough that if you spread its cost across all the cheap adds, each add is
> still cheap on average. That average is what **amortised O(1)** means.

**Node**

Too dense:

> Node's non-blocking I/O leverages an event-driven architecture, delegating operations to
> libuv's thread pool to avoid main-thread saturation.

Rewritten:

> Node runs your code on one thread. If your code stops and waits for a file, everything
> else waits too. So Node hands slow jobs like file reads to helper threads and carries on
> with other work. When a helper finishes, Node runs the function you left behind, the
> callback. That is how one thread serves a lot of requests at once.

Both rewrites are longer. That is fine. Length is cheap, confusion is not.

### The check

Before you consider a note done: could you say this out loud to a friend who does not code,
and would they get it? If not, it is not finished.

## Rule 2: it should read like a person wrote it

These notes are for you to revise from and for friends to read. They should sound like
someone explaining a topic to you, not like generated filler.

### No em dashes or en dashes

Never use an em dash (U+2014) or an en dash (U+2013), anywhere, in any file. Use a comma,
semicolon, colon, or full stop instead, or wrap the aside in parentheses, or split the
sentence in two. A hyphen in a compound word (`two-pointer`, `kebab-case`) is a different
character and is fine.

The reason is simple: those two characters are the clearest sign that text was generated
rather than typed. Nobody reaching for punctuation on a phone keyboard produces them.

`scripts/check-style.sh` enforces this, as a pre-commit hook, so a stray dash fails the
commit. The hook only runs once you have enabled it (see the setup steps), and it can be
skipped with `git commit --no-verify`, so it is a safety net rather than a wall. If a line
genuinely needs one of these characters, put `style-ignore` on that line and the check
skips it.

### The rest of sounding human

- Vary sentence length. All-medium-length sentences read like a template.
- Skip the throat-clearing openers. *In this section we will explore*, *Let us dive into*.
  Start with the actual point.
- Drop the tidy three-item lists that exist for rhythm rather than content. Two reasons are
  fine if there are only two.
- Cut praise for the topic. *This elegant technique*, *a powerful pattern*. Say what it
  does.
- Write in your own voice, including the shorthand you would use talking to a friend. A note
  that sounds like you is a note you remember.

# Content Security Policy (CSP)

> [!tldr]
> A response header that tells the browser exactly which sources of scripts and content it may load, so an injected script from anywhere else is refused outright.

Even if an attacker manages to get a `<script>` tag into the page, the browser itself will not execute it unless its source matches the policy. That makes CSP a second line of defence behind input cleaning and output encoding, not a replacement for either.

**Shows up in:** [[cross-site-scripting]], [[designing-the-four-layers]].

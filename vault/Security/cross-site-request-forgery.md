# Cross Site Request Forgery (CSRF)

> [!tldr]
> A malicious site tricks a logged-in user's browser into sending a request to a site they are already authenticated with, riding on cookies the browser attaches automatically.

---

## The attack

You are logged into `bank.com`, which stores your session in a cookie. You then visit `evil.com`, which contains a hidden form:

```html
<form action="https://bank.com/transfer" method="POST">
  <input type="hidden" name="amount" value="10000" />
  <input type="hidden" name="to" value="attacker" />
</form>
<script>document.forms[0].submit()</script>
```

The browser submits this to `bank.com` and automatically attaches your existing session cookie, since cookies are sent based on the target domain, not based on which page the request originated from. `bank.com` sees a valid, authenticated request and processes the transfer. You never intended to send it.

---

## The defences

| Defence | How |
| --- | --- |
| CSRF tokens | a random token embedded in the legitimate form, checked server side, that `evil.com` has no way to know or include |
| SameSite cookies | `SameSite=Strict` or `Lax` tells the browser not to attach the cookie on requests originating from another site |
| Checking the Origin or Referer header | reject requests whose origin does not match your own domain |

Modern practice is `SameSite=Lax` or `Strict` cookies as the default defence, with CSRF tokens as the belt-and-suspenders addition for state-changing requests.

The third defence is not using cookies for auth at all, since the whole attack depends on the browser attaching credentials by itself.

| CSRF applies | CSRF does not apply |
| --- | --- |
| a browser, with cookie based auth | an `Authorization: Bearer` header, which the client has to attach on purpose |
| anything that relies on the browser sending credentials for you | mobile apps and server to server calls, where there is no browser to trick |

> [!tip] The recall line
> Cookies are browser managed, headers are client managed. CSRF abuses the browser's trust, not a bug in your server.

---

## Where you store the auth token changes what you are exposed to

`localStorage` cannot be read by CSRF and can be read by XSS. An HttpOnly cookie is the exact opposite.

So there is no safe choice, only a swap of which attack you are exposed to, which is why both defences are needed either way. The storage table is in [[jwt]].

---

## The quick comparison

| | XSS | CSRF | CORS |
| --- | --- | --- | --- |
| What breaks | attacker's script runs on your page | attacker rides the victim's own cookies | none, it is a browser permission, not a vulnerability class |
| Who is tricked | the victim's browser into running attacker code | the victim's browser into sending an unwanted request | nobody, it decides what JavaScript is allowed to read |
| Main defence | escaping output, CSP ([[content-security-policy]]) | CSRF tokens, SameSite cookies | not a defence against an attack, it is an access control the server opts into |

See [[cross-site-scripting]] and [[cors]] for the other two.

# CORS

> [!tldr]
> CORS is a browser rule, enforced by the browser, that decides whether JavaScript on one site is allowed to read a response from another site. It is not a security feature of your API.

---

## The same origin policy

By default, a browser blocks JavaScript running on `siteA.com` from reading a response returned by `siteB.com`. That default is the same origin policy. CORS is the mechanism a server uses to opt certain other origins into being allowed.

---

## How the server opts in

```js
const cors = require('cors');

app.use(cors({
  origin: 'https://trusted-frontend.com',
  credentials: true,
}));
```

This sends back an `Access-Control-Allow-Origin` header. The browser checks that header against the page's own origin and only then lets the calling JavaScript read the response. The request still happens either way, the header only controls whether the browser lets the script see the result.

---

## CORS does not protect your API

> [!warning] Any tool that is not a browser ignores CORS entirely
> `curl`, Postman, a server calling your API and a mobile app all send the request directly. There is no browser in the way, so there is no same origin policy to enforce.
> CORS is a rule browsers apply to browser-run JavaScript, not a rule your server applies to the request.
> So `Access-Control-Allow-Origin: *` does not hand your API to new attackers. It only changes which websites' JavaScript may read the response.

Real authorization is a separate concern: auth tokens, session validation, rate limiting. CORS answers "can this browser tab's script see the response", not "should this caller be allowed to do this at all".

> [!tip] Interview line
> CORS protects users browsing other sites from having their logged-in session silently read by JavaScript on a page they did not mean to trust. It does not protect the API itself from a direct, non-browser caller.

See [[cross-site-request-forgery]] for the attack CORS is often confused with.

# Server-Side Rendering (SSR)

> [!tldr]
> The server builds the full HTML page before sending it, so the first screen shows up fast and a search engine can read it without running any JavaScript.

The alternative is client-side rendering (CSR): the server sends a near-empty page and the browser builds it after downloading and running the JavaScript bundle. CSR feels snappier once loaded, for an app-like interactive screen, but pays a blank-page cost upfront that SSR avoids.

The choice is per page, not per app: a content-heavy landing page wants SSR, an interactive dashboard behind a login usually does not need it.

**Shows up in:** [[designing-the-four-layers]].

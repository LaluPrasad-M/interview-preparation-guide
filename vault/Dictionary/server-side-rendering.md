# Server-Side Rendering (SSR)

> [!tldr]
> The server builds the finished HTML before sending it, so the first screen appears without waiting for JavaScript, and a crawler can read the page without running any.

The alternative is client-side rendering (CSR), where the server sends a nearly empty page plus a script bundle, and the browser builds the screen after downloading and running it.

| | SSR | CSR |
| --- | --- | --- |
| First response contains | the full page content | an empty `<div id="root">` |
| User sees content after | one round trip | download the bundle, run it, then fetch data |
| Search engine and link preview | reads it directly | may see a blank page |
| Server cost | renders every request, or caches it | serves static files |
| Navigating between pages | can feel heavier | instant, no server involved |

Both then need hydration, which is React attaching its event listeners to the HTML that already exists. Until hydration finishes, an SSR page can look ready while buttons do nothing, and that gap is the honest downside of the approach.

> [!tip] It is a per page decision, not a per app one
> A marketing page, a blog post or a product page wants SSR, because it is public, shareable and judged on how fast the first paint is. A dashboard behind a login usually does not, because nobody links to it and no crawler will ever see it.

**Shows up in:** [[designing-the-four-layers]].

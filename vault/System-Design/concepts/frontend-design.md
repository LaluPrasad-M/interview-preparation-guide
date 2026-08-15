# Frontend Design

> [!tldr]
> The only part of the system your user actually touches. Everything behind it can be perfect and they will still call the product bad if this part is slow or confusing.

---

## What a good frontend gives you

| What you get          | How                                                                                                                                                                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Better experience** | Readable fonts, buttons where people expect them, sizes neither tiny nor huge, enough contrast to read in sunlight.                                                                                                          |
| **Speed**             | Smaller files (minified bundles), load parts only when needed (lazy loading), keep what you fetched (caching), wait for the user to stop typing before searching (debounce), redraw only what changed (React's virtual DOM). |
| **Room to grow**      | Small reusable components instead of one giant file, so two people can work without stepping on each other.                                                                                                                  |
| **Safety**            | Block injected scripts ([[cross-site-scripting]]), stop other sites acting as your user (CSRF), tell the browser which scripts it may run (Content Security Policy), check both who the user is and what they may do.        |

---

## What a bad one costs

> [!warning] The two ways it goes wrong
> **It gets slow.** Too much JavaScript, components redrawing when nothing changed, heavy animations, huge unresized images.
>
> **It gets hard to change.** Nothing is reusable, state is scattered everywhere, no agreed style, so every feature takes longer than the last.

---

## Three decisions worth remembering

**Feature flags.** A switch that turns a feature on or off without shipping new code. Useful for showing a feature to ten percent of users first, and for turning something off at 2am without a deploy.

**State management.** One agreed place to keep data the whole app needs, using Redux, Zustand or React Context. Without it, two parts of the screen disagree about what is true.

**SSR or CSR.**

| Approach | Builds the page | Good for |
| --- | --- | --- |
| **SSR** | on the server | fast first screen, search engines can read it, content-heavy pages |
| **CSR** | in the browser | feels snappy once loaded, app-like interactive screens |

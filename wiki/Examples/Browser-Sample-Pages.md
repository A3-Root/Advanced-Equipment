# Browser Sample Pages

This index collects larger browser examples that show a complete page instead of only a short intel snippet.

The pages are split into public wiki docs and reusable source files under `sample_files/`:

- [Browser Sample Portal](Browser-Sample-Portal.md)
- [Browser Sample Regret](Browser-Sample-Regret.md)
- [Browser Sample Image Gallery](Browser-Sample-Gallery.md)

Recommended use:

1. Read the public wiki page for the example you want.
2. Open the matching folder in `sample_files/`.
3. Copy the HTML, Markdown, CSS, JS, and image fragments you want into your own mission content.
4. Pair any page that should feel discovered with browser history or another clue source.

The samples are intentionally different:

- Portal: mission-intel landing page.
- Regret: social feed style page.
- Image Gallery: image-heavy page with captions and a lightbox-style interaction pattern.

## File Layout

```text
sample_files/
  portal/
  regret/
  gallery/
```

Each folder contains an `index.html` page plus companion source files. Some folders also include a Markdown note or SVG asset set so you can see how AE3 handles more than one content type.

## How These Pages Actually Load

These samples are real HTML/CSS/JS, not the plain-text page model used by `AE3_desktop_fnc_registerWebpage` (see [Browser API](../Reference/Browser-API.md)). The Browser app renders full HTML pages directly, loaded by path rather than registered as a text string:

1. Copy a sample folder into your mission folder under `sites/`, e.g. `sites/portal/index.html` (matching the sample layout).
2. In the Browser address bar, or as a link/URL anywhere else in the mission (browser history, an email body, another page's `<a href>`), use a path address such as `sites/portal/index.html` instead of a bare intel-style URL.
3. The Browser resolves it as a real file: `.md` addresses are rendered through the built-in Markdown renderer; `.html` addresses (or any address containing a path separator) are loaded and shown as-is inside the Browser's page frame.
4. Inline `<style>`/`<script>` in the HTML works normally — that's why each sample is self-contained (see `sample_files/README.md`). Split `styles.css`/`app.js` files are there so you can see the same source un-inlined if you'd rather maintain it that way, but only the `index.html` you actually reference needs to be self-contained for the in-game page to work.
5. Absolute paths into another mod's PBO (`\z\othermod\...\page.html`) resolve the same way, so an addon can ship its own bundled pages instead of relying on mission files.
6. Relative links inside the page (e.g. `<a href="../wiki/index.html">`) resolve against the directory of the page that contains them, so a multi-page site can link between its own pages without full paths.

This is a different, lower-level mechanism than `registerWebpage` — use `registerWebpage` for short scripted/dynamic intel text, and this file-based path for a fully designed page like the samples here. Pair either with a [browser history entry](../Reference/Browser-API.md#browser-history) so players have a reason to type the address.

## Related Pages

- [Add Webpages and Browser History](Add-Webpages-and-Browser-History.md)
- [Browser API](../Reference/Browser-API.md)

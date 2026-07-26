# Browser and Webpages

The Browser app displays in-game webpages created for the mission. Browser content is useful for intranet pages, fake public websites, objective boards, status pages, reports, and searchable clues. It is a mission-intel system, not a real internet browser — every page is authored by the mission maker.

## What a Webpage Contains

A browser page has:

- **URL** — the address players type or open from history, e.g. `intel.root/convoys`. Use readable fictional domains (`mail.node/...`, `depot.local/...`) rather than real-world URLs.
- **Title** — the page heading shown in the Browser app.
- **Content** — the text players read.

Pages registered with `AE3: Add Webpage` (or `AE3_desktop_fnc_registerWebpage`) are text-focused. Use `AE3: Add Media` for images, video, or audio instead of trying to embed them in a page.

For a fully designed page instead — real HTML with inline CSS/JS, like a genuine mini-website — the Browser also loads pages by file path (e.g. `sites/portal/index.html` in your mission folder) instead of registering text content. See [Browser Sample Pages](../Examples/Browser-Sample-Pages.md) for the drop-in examples under `sample_files/` (`gallery/`, `portal/`, `regret/`) and exactly how the path-based loading works.

## Browser History

Browser history is a separate clue trail stored per laptop at `/var/log/browser_history`. It shows that someone visited a URL — a history entry does not automatically create the webpage, and a webpage without a history entry is invisible unless players already know the URL.

For a complete browser clue, add both:

1. A webpage (`AE3: Add Webpage`).
2. A browser history entry pointing to that webpage's URL (`AE3: Add Browser History`), with a display time if you want to imply *when* it was visited.

## No-Code Setup

In 3DEN:

1. Place a laptop.
2. Set Interface Mode to GUI or Both.
3. Place `AE3: Add Webpage`. Fill in URL, Title, Content.
4. Sync it to the laptop.
5. Place `AE3: Add Browser History`. Use the same URL, set the displayed time if desired.
6. Sync it to the laptop.
7. Preview and open the Browser app.

## Good Browser Design

- Keep URLs short and memorable (`intel.root/convoys`, not a long random string).
- Make history entries point to useful content — a history trail to a dead page wastes a clue.
- Use page titles that tell players what they found at a glance.
- Put long background lore in files or mail, not one giant page.
- Use multiple small pages linked by a Browser or Files "index" page when players should follow a trail (see the complete setup example in [Browser API](../Reference/Browser-API.md)).
- Combine with other systems: a password hint on a webpage, the protected payload in a [locked file](Encryption-and-Security.md); a URL mentioned in an [email](Intel-Mail-Chat-Media.md) body.

## Related Pages

- [Browser API](../Reference/Browser-API.md) — `registerWebpage`, `addHistoryEntry`, full scripted examples.
- [Extending Browser Webpages](../Developer/Extending-Browser-Webpages.md) — custom HTML/CSS/JS pages.
- [Add Webpages and Browser History](../Examples/Add-Webpages-and-Browser-History.md) — step-by-step tutorial.
- `sample_files/` — drop-in HTML/CSS/JS page examples.

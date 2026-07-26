# Browser Sample Portal

The portal sample is a mission-intel landing page. It looks like a real site home page instead of a bare clue card.

## What It Shows

- A header with navigation links.
- A featured alert panel.
- Card-based sections for status, files, and quick links.
- A Markdown companion note for players who browse the folder directly.
- Split source files for HTML, CSS, and JS.

## File Set

```text
sample_files/portal/index.html
sample_files/portal/styles.css
sample_files/portal/app.js
sample_files/portal/brief.md
```

## Why It Is Useful

Use this pattern when the page should feel like a real internal portal:

- an operations dashboard,
- a depot status page,
- a command post landing page,
- or a fake company intranet.

The page should be readable on its own, but it also gives you a good place to tuck links to other browser pages, files, or browser-history clues.

## Example Pattern

```text
Portal Home
├─ Situation Brief
├─ Active Notices
├─ Documents
└─ Field Notes (Markdown)
```

## Related Pages

- [Browser Sample Pages](Browser-Sample-Pages.md)
- [Add Webpages and Browser History](Add-Webpages-and-Browser-History.md)

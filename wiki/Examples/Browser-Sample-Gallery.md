# Browser Sample Image Gallery

The gallery sample is an image-heavy page that shows how to build a browsable media wall with captions, filtering, and a larger preview.

## What It Shows

- A hero section with a featured image.
- A responsive thumbnail grid.
- Filter buttons driven by JS.
- A lightbox-style preview interaction.
- Markdown notes for captions or a curator sheet.
- Separate SVG image assets for reusable source art.

## File Set

```text
sample_files/gallery/index.html
sample_files/gallery/styles.css
sample_files/gallery/app.js
sample_files/gallery/gallery.md
sample_files/gallery/assets/*.svg
```

## Why It Is Useful

Use this pattern when the page should feel visual:

- photo archive,
- surveillance contact sheet,
- propaganda board,
- evidence wall,
- or mission briefing gallery.

It is also a good place to pair browser pages with media files, because the page can point players toward the underlying images or the files app.

## Example Pattern

```text
Gallery
├─ Hero image
├─ Tag filters
├─ Thumbnail wall
└─ Curator notes
```

## Related Pages

- [Browser Sample Pages](Browser-Sample-Pages.md)
- [Add Webpages and Browser History](Add-Webpages-and-Browser-History.md)

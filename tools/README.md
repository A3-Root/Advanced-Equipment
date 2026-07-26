# AE3 Tools

## png2b64 - image → base64 sidecar for the desktop/browser

Arma's CEF web control cannot reliably load every image through the engine texture sampler, so the
AE3 web desktop and Browser serve raster images (PNG/JPG/GIF) as a **base64 sidecar** placed next to
the image: `<image>.b64`. At runtime `js/bridge.js` (`AE3.loadImage`) reads that file with
`RequestFile` and wraps its contents in a `data:` URL for an `<img>` or CSS background.

Use these scripts to generate the sidecars. They write **raw base64** text (no `data:` prefix, no
line wrapping) — exactly what the bridge expects.

### PowerShell (Windows)

```powershell
# one file  -> creates wallpaper_1.png.b64 next to it
./tools/png2b64.ps1 addons/desktop/images/wallpaper_1.png

# a whole mission images folder (recursive)
./tools/png2b64.ps1 -Recurse "C:\...\MyMission.Altis\media\images"
```

### Python (cross-platform)

```bash
python tools/png2b64.py addons/desktop/images/wallpaper_1.png
python tools/png2b64.py --recurse "C:/.../MyMission.Altis/media/images"
```

### Using a base64 image in-game

- **Mission image**: put `myimage.png` and its `myimage.png.b64` in your mission folder, then
  reference `myimage.png` from media/registerMedia or a page — `loadImage` finds the `.b64` sidecar
  automatically. (You can also reference the `.b64` path directly.)
- **Desktop wallpapers**: the bundled wallpapers under `addons/desktop/images/` ship as
  `wallpaper_*.png.b64` and are loaded via these sidecars (not the `.paa`). Drop your own
  `something.png` + `something.png.b64` there (or register an image via `registerMedia`) to add more.

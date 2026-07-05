#!/usr/bin/env python3
"""Convert image files (PNG/JPG/GIF) to the base64 ".b64" sidecars the AE3 desktop/browser reads.

The AE3 web desktop (CEF) cannot reliably sample every image through the engine texture loader, so
raster images are served as a base64-encoded sidecar next to the image: "<image>.b64". js/bridge.js
(AE3.loadImage) reads that file via RequestFile and wraps it as a data: URL for an <img>/CSS
background. This script writes those sidecars as RAW base64 text (no "data:" prefix, no wrapping).

Usage:
    python png2b64.py IMAGE_OR_FOLDER [MORE ...] [--recurse]

Examples:
    python png2b64.py addons/desktop/images/wallpaper_1.png
    python png2b64.py --recurse "C:/.../MyMission.Altis/media/images"
"""
import base64
import os
import sys

EXTS = (".png", ".jpg", ".jpeg", ".gif")


def convert_one(path):
    with open(path, "rb") as f:
        data = f.read()
    out = path + ".b64"
    with open(out, "w", encoding="ascii") as f:
        f.write(base64.b64encode(data).decode("ascii"))
    print(f"Wrote {out} ({os.path.getsize(out)} bytes)")


def main(argv):
    recurse = "--recurse" in argv
    targets = [a for a in argv if a != "--recurse"]
    if not targets:
        print(__doc__)
        return 1
    for p in targets:
        if os.path.isdir(p):
            if recurse:
                for root, _dirs, files in os.walk(p):
                    for name in files:
                        if name.lower().endswith(EXTS):
                            convert_one(os.path.join(root, name))
            else:
                for name in os.listdir(p):
                    full = os.path.join(p, name)
                    if os.path.isfile(full) and name.lower().endswith(EXTS):
                        convert_one(full)
        elif os.path.isfile(p):
            convert_one(p)
        else:
            print(f"Not found: {p}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

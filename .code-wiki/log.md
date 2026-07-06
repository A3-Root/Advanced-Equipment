---
title: wiki operation log
last-updated: 2026-06-30
---

# code wiki operation log

Append-only log for code-wiki maintenance actions. Actions: created, updated, re-verified, archived, discovered, lint.

## log

2026-06-30 | created | wiki-infrastructure | initial code-wiki scaffold created in `.code-wiki/`
2026-06-30 | created | desktop-gui-and-browser | wiki-bootstrap draft from addon scan
2026-06-30 | created | eden-zeus-tooling | wiki-bootstrap draft from addon scan
2026-06-30 | created | network-routing-and-ssh | wiki-bootstrap draft from addon scan
2026-06-30 | created | armaos-terminal | wiki-bootstrap draft from addon scan
2026-06-30 | created | power-model | wiki-bootstrap draft from addon scan
2026-06-30 | created | filesystem-model | wiki-bootstrap draft from addon scan
2026-06-30 | created | multiplayer-locality-and-sync | wiki-bootstrap draft from addon scan
2026-06-30 | created | flashdrive-usb | wiki-bootstrap draft from addon scan
2026-06-30 | created | interaction-equipment | wiki-bootstrap draft from addon scan
2026-06-30 | created | desktop-intel-and-communications | wiki-bootstrap draft from addon scan
2026-06-30 | verified | desktop-gui-and-browser | wiki-bootstrap: auto-approved high-confidence draft
2026-06-30 | verified | eden-zeus-tooling | wiki-bootstrap: auto-approved high-confidence draft
2026-06-30 | verified | network-routing-and-ssh | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | armaos-terminal | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | power-model | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | filesystem-model | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | desktop-intel-and-communications | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | multiplayer-locality-and-sync | wiki-bootstrap: maintainer corrections applied
2026-06-30 | verified | flashdrive-usb | wiki-bootstrap: maintainer approved draft
2026-06-30 | verified | interaction-equipment | wiki-bootstrap: maintainer approved draft
2026-06-30 | lint | wiki-topics | fixed reciprocal links, token estimate, rank metadata, and duplicate trigger paths
2026-07-04 | updated | eden-zeus-tooling | documented optional ZEN (Zeus Enhanced) Dynamic Dialog compat for all 10 Zeus modules
2026-07-05 | updated | eden-zeus-tooling | Add Intel split into standalone per-type Zeus modules; Add User ZEN defaults admin/admin123
2026-07-05 | updated | desktop-gui-and-browser | Terminal app + desktop<->CLI switching (sys_switch_cli / desktop command); executable file green tint + run (fs_list exec flag, sys_run_file)
2026-07-05 | updated | desktop-gui-and-browser | mission-first web roots + custom domains (registerSite/web_sites/Add Website); per-user wallpapers + picker; calendar time; symlink exec; media filename+overwrite
2026-07-05 | updated | eden-zeus-tooling | laptop clone case-fix + network restore; Zeus filesystem browser pick fixes; ZEN calendar time; ZEN interface access OWNERS; Add Website module
2026-07-06 | updated | desktop-gui-and-browser | browser tabs; home=RootNet; site-relative .md; shell assets mod-first (RPT fix); wallpapers via .png.b64 sidecars + png2b64 tool
2026-07-06 | updated | eden-zeus-tooling | laptop clone real fix: filesystem applied server-local (not broadcast) so getRemoteVar/userlist no longer stalls; ensureInit target
2026-07-06 | updated | eden-zeus-tooling | Save/Restore Laptop root cause: modules had no nearest-laptop fallback so a drop-on-laptop placement passed an empty target list; added crashDevice-style _isLaptop filter + nearestObjects fallback. ZEN restore no longer fakes a slot1 when buffer empty. Added CfgEditorSubcategories (8 subcats) + editorSubcategory on all AE3 objects for 3DEN/Zeus tree
2026-07-06 | updated | desktop-gui-and-browser | browser: DefaultTheme CBA setting now client-overridable (isGlobal 0); first-tab home no longer flashes Portal (re-nav home when page list resolves); tab close glyph via &#215; entity (no raw non-ASCII); in-site subpath links join curDir; history stores resolved targets so Back restores exact page; curDir adopted only on successful load
2026-07-06 | updated | desktop-gui-and-browser | removed bundled sample sites (ui/web/sites portal+wiki, ui/web/wiki); browser home is now a static inline RootNet page (ROOTNET_HOME) until the seeded rootnet.root page list loads - no Portal fallback; dropped wiki friendly-name shortcut; AddWebsite module default root now sites/mysite
2026-07-06 | updated | flashdrive-usb | arsenal collapse: ITEM_ID_UNIQUEENTRY variants set scopeArsenal=0 + ace_arsenal_uniqueBase so only the single base Flash Drive shows in arsenal (ACRE pattern)
2026-07-06 | updated | eden-zeus-tooling, desktop-gui-and-browser | AddFile "This is a Picture" checkbox + image-type combo (Zeus/3DEN/ZEN): raw base64 stored as AE3_MEDIA|image|b64|<mime>|<data> inline marker; device_addFile gains _isPicture/_pictureType params (after _overwrite); web Image Viewer renders it as a data URL + new "Decode B64" paste-and-render button (temporary, no VFS write); native viewer declines b64; cap AE3_MAX_PICTURE_B64 2MB enforced server-side

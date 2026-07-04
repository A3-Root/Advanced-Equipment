---
topic: desktop-gui-and-browser
status: verified
last-verified: 2026-07-04
confidence_score: 1.0
priority: core
rank: 1
tokens: ~980
code-paths:
  - addons/desktop/
  - addons/desktop/functions/fnc_jsRouter.sqf
  - addons/desktop/functions/fnc_desktop_open.sqf
  - addons/desktop/CfgAE3Apps.hpp
related-topics: [armaos-terminal, filesystem-model, network-routing-and-ssh, eden-zeus-tooling, desktop-intel-and-communications, flashdrive-usb, multiplayer-locality-and-sync]
related-docs:
  - wiki/Systems/Desktop-GUI.md
  - wiki/Systems/Browser.md
  - wiki/Reference/Desktop-API.md
  - wiki/Reference/Browser-API.md
---

# Desktop GUI And Browser

## overview

The desktop component provides the graphical laptop desktop, native app registry, browser bridge, web desktop command router, mail/chat/browser/calendar/media features, and runtime extension points for other addons.

## current behavior

- `AE3_desktop_fnc_desktop_open` opens the native GUI desktop for a laptop, pulls filesystem/user state, claims the laptop as in use, creates desktop icons, and restores previous window state.
- Native desktop apps are declared in `CfgAE3Apps` or registered at runtime with `AE3_desktop_fnc_registerApp`.
- Web external apps are registered with `AE3_desktop_fnc_registerExtApp`; the web desktop replaces same-id external apps, removes absent external apps from later `ext_apps` pushes, and supports `deviceList` plus `launcher` template kinds. Desktop files with resolved content `app=<id>` launch that app even when the visible filename is not `.app`.
- The built-in app set includes Terminal, Files, Settings, Notepad, Mail, Chat, Browser, Calendar, Map, CCTV, Music, and SysInfo.
- The web desktop uses a browser control bridge. JavaScript sends JSON messages with `command`, `rid`, and `data`; `AE3_desktop_fnc_jsRouter` dispatches those messages to SQF handlers and replies through `AE3_desktop_fnc_jsSend`.
- Files and Notepad route through `AE3_desktop_fnc_fsHandle`, which calls the same virtual filesystem functions used by CLI commands.
- Browser pages are registered with `AE3_desktop_fnc_registerWebpage`; global pages live in `missionNamespace` under `AE3_Desktop_Webpages`, while laptop-targeted pages live on the object under the same key.
- Browser history is stored in the laptop filesystem at `/var/log/browser_history`.
- Post-init seeds a default RootNet page and registers client events that notify open web apps about mail, chat, calendar, SSH, USB volume, system, network, and browser page changes.
- Desktop auth mirrors terminal auth, including direct-root restrictions through `AE3_AllowRootLogin`.

## decisions

- The web desktop funnels JavaScript calls through one SQF router to keep the browser bridge auditable and avoid scattering browser event handlers across apps.
- Desktop apps use both config registration and runtime registration: config covers built-in/default apps, while runtime registration gives addon authors a lightweight extension path.
- State-dependent external web apps should prefer `requiresFunction` when availability depends on mounted USBs or computed client state; addons can use the local `ae3_desktop_ready` event and later state-change events to push refreshed filtered `ext_apps` lists.
- Browser content is registered as in-game intel, not loaded from external URLs, so Arma's browser control stays an internal UI and mission-safe content surface.
- GUI file access intentionally reuses CLI filesystem calls to keep owner and permission behavior consistent across GUI and TUI.
- The desktop shows a static in-use texture on the laptop object while the real GUI exists only on the operator client, limiting network traffic and avoiding an active rendered desktop for observers.

## gotchas

- `fnc_jsRouter.sqf` is a major hotspot. New web commands should be reviewed for auth, locality, reply handling, and serialization before adding more cases.
- HashMaps do not serialize safely through every multiplayer path; SSH command handling converts operation arguments to plain arrays/strings before sending a CBA server event.
- Browser history writes require the laptop filesystem to exist and silently fail inside `try/catch` if the history file cannot be created.
- Session resume is tied to player UID; `ready` auto-resumes only when `AE3_desktop_sessionOwner` matches `getPlayerUID player`.
- Runtime app registration is local effect. Call it on every client that should see the app.
- External app removal only applies to apps marked by the web extension registry (`external: true`); built-in apps are not removed by `ext_apps` refreshes. Registry icons can carry `iconPath`, but browser rendering depends on the image format supported by CEF.

## re-verify when

- `fnc_jsRouter.sqf`, web app command names, `ui/web/js/extapps.js`, `ui/web/js/desktop.js`, `CfgAE3Apps.hpp`, desktop window manager functions, browser history storage, or `registerWebpage` changes.
- A new desktop app, browser feature, or extension command is added.

## references

- `addons/desktop/functions/fnc_desktop_open.sqf`
- `addons/desktop/functions/fnc_jsRouter.sqf`
- `addons/desktop/functions/fnc_fsHandle.sqf`
- `addons/desktop/functions/fnc_registerApp.sqf`
- `addons/desktop/functions/fnc_registerExtApp.sqf`
- `addons/desktop/ui/web/js/extapps.js`
- `addons/desktop/ui/web/js/desktop.js`
- `addons/desktop/ui/web/js/wm.js`
- `addons/desktop/functions/fnc_registerWebpage.sqf`
- `addons/desktop/XEH_postInit.sqf`
- `addons/desktop/CfgAE3Apps.hpp`


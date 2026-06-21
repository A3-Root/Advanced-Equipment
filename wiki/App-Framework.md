# Desktop App Framework

The AE3 desktop (GUI laptop interface) supports third-party applications. Apps appear as
desktop icons and open in draggable windows inside the desktop display.

## Registering an app

### Via config (recommended for addons)

```cpp
class CfgAE3Apps
{
    class MyMod_HackTool : AE3_DesktopApp
    {
        displayName = "Hack Tool";
        entry = "MyMod_fnc_hackToolApp"; // function name, resolved via missionNamespace
        defaultSize[] = {0.6, 0.6};      // fraction of the desktop area
        showOnDesktop = 1;               // desktop icon
        singleton = 1;                   // only one window instance
    };
};
```

### At runtime (missions, scripts)

```sqf
// local effect - run on every client that should see the app (e.g. initPlayerLocal.sqf)
["myMission_notes", "Mission Notes", "myMission_fnc_notesApp", [0.5, 0.5]] call AE3_desktop_fnc_registerApp;
```

## The entry function

Called when the window opens:

```sqf
// MyMod_fnc_hackToolApp
params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _display = ctrlParent _ctrlGroup;

// Create your controls INSIDE the window group via ctrlCreate.
// y = 0.04 is below the titlebar; sizes are screen-UI coordinates.
private _label = _display ctrlCreate ["RscText", -1, _ctrlGroup];
_label ctrlSetPosition [0.01, 0.05, 0.4, 0.04];
_label ctrlSetText "Hello from my app";
_label ctrlCommit 0;

// Optional callbacks
createHashMapFromArray [
    ["onClose", { params ["_winId", "_computer"]; /* cleanup */ }]
]
```

Notes:
- `_computer` is the laptop object. Its filesystem was pulled from the server when the
  desktop opened: `_computer getVariable "AE3_filesystem"`. Filesystem writes are pushed
  back to the server when the desktop closes; use the standard `AE3_filesystem_fnc_*`
  functions for structured access and permission checks.
- The desktop runs only on the operator's client. Do not broadcast UI state.
- Useful helpers: `AE3_desktop_fnc_wm_createWindow`, `AE3_desktop_fnc_wm_closeWindow`,
  `AE3_desktop_fnc_openFile`, `AE3_desktop_fnc_wm_getTheme`.

## CLI commands

Existing CLI commands (CfgOsFunctions and filesystem executables added by mods like Root
Cyberwarfare) work unchanged in the desktop's **Terminal** app - no porting needed.

Commands can opt out of SSH execution with `sshCompatible = 0;` in their config entry
(used for interactive/graphical programs).

## Media registry (mission makers)

Register media files (shipped in mods or the mission) so players can open them on laptops:

```sqf
// [source path, type (image|video|audio), virtual filesystem destination, targets]
// targets: array of laptops | "all" | "future" (all current AND future laptops)
["\myMod\video\intel.ogv", "video", "/home/user/intel.ogv", "all"] call AE3_desktop_fnc_registerMedia;
```

Works from any machine (routed to the server) and is JIP-safe. The media appears as a
marker file in the laptop filesystem; opening it in the Files app (or `cat` showing the
marker) plays/displays the media. Note: the engine cannot enumerate files inside mods at
runtime - media must be registered with explicit paths.

## Planting intel (mission makers)

Every desktop app reads from plain virtual-filesystem files with documented formats, so the
existing **Zeus AddFile module**, **3DEN AddFile module** and `AE3_filesystem_fnc_device_addFile`
all work as universal intel tools - plus dedicated APIs (all callable from any machine, JIP-safe):

| Intel | Found in | File / format | API |
|-------|----------|---------------|-----|
| Documents | Files, Notepad, `cat` | any text file | `device_addFile` / AddFile module |
| Images / video / audio | Files app viewers | `AE3_MEDIA\|<type>\|<path>` marker | `AE3_desktop_fnc_registerMedia` |
| Emails | Mail app | `/var/mail/<name>`: `From:` / `Subject:` headers + blank line + body | `AE3_desktop_fnc_addEmail [target\|"all", from, subject, body]` |
| Chat messages | Chat app, `cat /var/mail/inbox` | `/var/mail/inbox`, one line per message | `msg` command / `ae3_network_imSend` |
| Webpages | Browser app (custom URLs) | global registry | `AE3_desktop_fnc_registerWebpage [url, title, lines]` |
| Browser history | Browser app History, `cat /var/log/browser_history` | `[HH:MM] url` per line | `AE3_desktop_fnc_addHistoryEntry [target\|"all", url, time]` |
| Calendar entries | Calendar app | `/home/user/calendar`: `DATE \| TITLE \| DETAILS` per line | `AE3_desktop_fnc_addCalendarEvent [target\|"all", date, title, details]` |

### Zeus / 3DEN: "AE3: Add Intel" module

The **AE3: Add Intel** module (Zeus and 3DEN, category AE3) covers all of the above without
scripting: pick the type (email / webpage / history / calendar / media) and fill three fields
(labels adapt to the type). Placed on a laptop it targets that laptop; placed anywhere else it
targets **all** laptops (in 3DEN you can also sync the module to specific laptops). Webpage
content supports `|` for line breaks and `[[url|label]]` link tokens.

### Browser pages and links

Page content lines may contain `[[url|label]]` tokens - they render as underlined text and
appear as clickable link buttons under the page. The browser has Back and session history;
`home.root` lists all registered pages as links. Every visit lands in
`/var/log/browser_history`.

### CCTV cameras

```sqf
["Compound Gate", _cctvProp] call AE3_desktop_fnc_registerCamera; // optional: offset, direction
```

Registered cameras are viewable in the CCTV desktop app (local render-to-texture on the
viewing client only - no network traffic).

Example mission setup:

```sqf
["intel.root/convoys", "Convoy Schedule", ["0400 - Route Red", "0600 - Route Blue"]] call AE3_desktop_fnc_registerWebpage;
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;   // "they looked this up"
[_laptop, "informant", "Meeting", "Safehouse, sector C4, 0300."] call AE3_desktop_fnc_addEmail;
[_laptop, "2026-06-24 04:00", "Convoy departs", "Route Red, 3 trucks"] call AE3_desktop_fnc_addCalendarEvent;
["\myMod\img\map_photo.paa", "image", "/home/user/photo.paa", [_laptop]] call AE3_desktop_fnc_registerMedia;
```

Customization: themes (colors + font per theme, 3 built in, extendable via `CfgAE3Themes`),
per-laptop wallpaper picked in Settings from registered images, per-laptop theme selection.

## Interface mode and access control

Per-laptop interface selection and access are mission-maker / framework controlled - players
cannot switch:

```sqf
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;   // "cli" | "gui" | "both"
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;            // sides/UIDs
[_laptop, "gui", { (_this select 1) getVariable ["hasKey", false] }] call AE3_desktop_fnc_setInterfaceAccess; // CODE
[_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface;            // the check, public
```

Also available as the 3DEN laptop attribute "Interface (CLI / GUI / Both)" and the
`AE3_Desktop_DefaultMode` CBA setting. While the desktop is in use, other players see a
static lock screen on the laptop texture (zero GUI sync traffic by design).

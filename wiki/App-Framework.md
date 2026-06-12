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

## Interface mode

Per-laptop CLI/GUI selection:

```sqf
[_laptop, "gui"] call AE3_desktop_fnc_setInterfaceMode; // or "cli"
```

Also available via the ACE interaction "Switch Interface (CLI/GUI)" on the laptop and the
`AE3_Desktop_DefaultMode` CBA setting. While the desktop is in use, other players see a
static lock screen on the laptop texture (zero GUI sync traffic by design).

# Extending Desktop GUI

The Desktop GUI can be extended with native SQF apps, app launcher files, media/file handlers, and the web desktop bridge. This guide focuses on native SQF apps and integration patterns. For the Browser-specific content system, see [Extending Browser Webpages](Extending-Browser-Webpages.md).

## Extension Options

| Need | Use |
| --- | --- |
| Add a reusable GUI app from an addon | `CfgAE3Apps`. |
| Add a mission-specific GUI app | `AE3_desktop_fnc_registerApp`. |
| Open a file/media item | `AE3_desktop_fnc_openFile`. |
| Add a Browser page/history | Browser API. |
| Add a web desktop template integration | `registerExtApp` and `registerCmd`. |

## Native App Lifecycle

1. App is registered by config or runtime script.
2. Desktop builds app icon if `showOnDesktop` is enabled.
3. Player opens the app.
4. Window manager creates a window and calls the app entry function.
5. App creates controls inside the provided control group.
6. App optionally returns callbacks such as `onClose`.
7. Window manager handles focus, minimize, close, and taskbar behavior.

## Runtime App Registration

```sqf
if (hasInterface) then {
    ["myMod_tools", "Tools", "myMod_fnc_toolsApp", [0.55, 0.5], true, true] call AE3_desktop_fnc_registerApp;
};
```

Arguments:

```sqf
[_className, _displayName, _entry, _size, _showOnDesktop, _singleton]
```

Runtime registration is local. Run it on every client, usually in your addon's client init path.

## Config App Registration

```cpp
class CfgAE3Apps
{
    class myMod_tools
    {
        displayName = "Tools";
        entry = "myMod_fnc_toolsApp";
        icon = "";
        defaultSize[] = {0.55, 0.5};
        showOnDesktop = 1;
        singleton = 1;
        requiresFilesystem = 1;
    };
};
```

Use config registration when the app is part of an addon and should always exist when that addon is loaded.

## Entry Function Contract

```sqf
myMod_fnc_toolsApp = {
    params ["_winId", "_ctrlGroup", "_computer", "_args"];

    private _title = _ctrlGroup ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.02, 0.02, 0.5, 0.04];
    _title ctrlSetText "Tools ready";
    _title ctrlCommit 0;

    createHashMapFromArray [
        ["onClose", {
            // Cleanup any handlers or resources.
        }]
    ]
};
```

Important rules:

- Create controls inside `_ctrlGroup`.
- Use `_computer` for laptop state.
- Do not assume `player` is the authenticated laptop user.
- Clean up event handlers, cameras, timers, and render targets.
- Keep long server calls asynchronous or routed through events.

## Reading the Logged-In User

Desktop apps should use the desktop session state to identify the user when needed. If your app is launched from filesystem/user context, pass the user through `_args` or read the same state used by built-in apps in surrounding code.

Do not hard-code `admin` unless the app is intentionally root/admin-only.

## Working with Files

Use the Filesystem API for raw file operations:

```sqf
private _fs = _computer getVariable "AE3_filesystem";
private _content = [[], _fs, "/home/admin/orders.txt", "admin", 0] call AE3_filesystem_fnc_getFile;
```

Use Desktop helpers for content that has app-specific marker formats:

```sqf
["media\photo.jpg", "image", "/home/admin/Desktop/photo.jpg", [_computer], "mission"] call AE3_desktop_fnc_registerMedia;
[_computer, "/home/admin/Desktop/secret.txt", "hunter2", "Payload"] call AE3_desktop_fnc_addLockedFile;
```

Open files through:

```sqf
[_computer, "/home/admin/Desktop/photo.jpg", "admin"] call AE3_desktop_fnc_openFile;
```

This preserves built-in behavior for text, media, locked files, launchers, and future file types.

## Server Calls from GUI Apps

GUI controls are client-local. If a button changes mission state, send a server event:

```sqf
private _button = _ctrlGroup ctrlCreate ["RscButton", -1];
_button ctrlSetText "Open";
_button ctrlAddEventHandler ["ButtonClick", {
    ["myMod_openRelay", []] call CBA_fnc_serverEvent;
}];
```

Server handler:

```sqf
if (isServer) then {
    ["myMod_openRelay", {
        missionNamespace setVariable ["myMod_relayOpen", true, true];
    }] call CBA_fnc_addEventHandler;
};
```

If the server needs to reply to one client, use CBA target events or a public object variable that the app refreshes.

## Refreshing Open Apps

AE3 uses global/local events to refresh apps when backend state changes. If your app watches custom state, define your own event:

```sqf
["myMod_relayChanged", {
    // Refresh visible controls.
}] call CBA_fnc_addEventHandler;
```

After server state changes:

```sqf
["myMod_relayChanged", []] call CBA_fnc_globalEvent;
```

For built-in state, prefer built-in APIs that already emit refresh events.

## App Launcher Curation

AE3 seeds launchers under:

```text
/usr/share/applications
```

User desktops contain launcher files or symlinks:

```text
/home/admin/Desktop/files.app
/home/admin/Desktop/browser.app
```

To curate an app set for a user, adjust that user's Desktop folder instead of removing the app globally.

Example:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
[[], _fs, "/home/admin/Desktop/tools.app", "/usr/share/applications/myMod_tools.app", "admin"] call AE3_filesystem_fnc_symlink;
_laptop setVariable ["AE3_filesystem", _fs, true];
```

## Testing Checklist

1. App icon appears after laptop login.
2. App opens in GUI-only and both-mode laptops.
3. App does not appear for users who should not have its launcher.
4. App closes cleanly without leaving handlers.
5. App works after JIP.
6. App works with two clients opening different laptops.
7. App handles laptop power loss or desktop close.
8. App does not make server-only calls from client UI without routing.

## Related Pages

- [Desktop API](../Reference/Desktop-API.md)
- [Desktop Apps](../Reference/Desktop-Apps.md)
- [Filesystem API](../Reference/Filesystem-API.md)
- [Locality and Multiplayer](Locality-and-Multiplayer.md)

# Desktop API

The Desktop component provides the graphical interface side of AE3: interface mode/access, native desktop apps, web desktop extension hooks, browser pages, mail, media, calendar content, CCTV registration, locked files, and GUI-open helpers.

This page documents script-facing functions. For non-script workflows, see the Eden, Zeus, Mission Maker, and System guides.

## Interface Mode

### `AE3_desktop_fnc_setInterfaceMode`

Controls which interface a laptop offers to players.

```sqf
[_computer, _mode] call AE3_desktop_fnc_setInterfaceMode;
```

Arguments:

| Index | Type | Values |
| --- | --- | --- |
| `0` | Object | Laptop object. |
| `1` | String | `"cli"`, `"gui"`, or `"both"`. |

Return value: none.

The call can be made from a client; the function routes to the server and stores the mode as a public object variable.

Example:

```sqf
if (isServer) then {
    [_laptopA, "gui"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptopB, "cli"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptopC, "both"] call AE3_desktop_fnc_setInterfaceMode;
};
```

Use this when a script needs to override the Eden Interface Mode attribute or mission-wide CBA default.

## Interface Access

### `AE3_desktop_fnc_setInterfaceAccess`

Controls who may open one interface on a laptop.

```sqf
[_laptop, _iface, _condition] call AE3_desktop_fnc_setInterfaceAccess;
```

Arguments:

| Index | Type | Meaning |
| --- | --- | --- |
| `0` | Object | Laptop object. |
| `1` | String | `"cli"` or `"gui"`. |
| `2` | Code or Array | Access condition. |

Access condition forms:

| Form | Meaning |
| --- | --- |
| `{ true }` | Everyone can access. |
| `{ false }` | Nobody can access. |
| `[west]` | Players on side west can access. |
| `["76561198000000000"]` | Player with this UID can access. |
| `[west, "76561198000000000"]` | Either listed side or UID can access. |
| `{ params ["_laptop", "_player"]; ... }` | Custom condition. Return bool. |

Examples:

```sqf
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "cli", ["76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "gui", { (_this select 1) getVariable ["myMission_hasKeycard", false] }] call AE3_desktop_fnc_setInterfaceAccess;
```

The function routes to the server and broadcasts the stored condition for JIP consistency.

### `AE3_desktop_fnc_canAccessInterface`

Checks whether a player may open an interface.

```sqf
private _allowed = [_laptop, _player, _iface] call AE3_desktop_fnc_canAccessInterface;
```

Example:

```sqf
if ([_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface) then {
    [_laptop] spawn AE3_desktop_fnc_desktop_open;
};
```

This function evaluates both the laptop interface mode and the per-interface condition.

## Opening the GUI

### `AE3_desktop_fnc_desktop_open`

Opens the native SQF GUI desktop for a laptop.

```sqf
[_computer] spawn AE3_desktop_fnc_desktop_open;
```

Use `spawn`, not `call`, because the function pulls remote variables and expects scheduled execution.

Normal players should open the desktop through ACE interactions. Call this directly only from custom interaction code or developer tooling.

### `AE3_desktop_fnc_desktop_openWeb`

Opens the CEF/web-browser desktop implementation.

```sqf
private _display = [_computer] call AE3_desktop_fnc_desktop_openWeb;
```

This is a lower-level web desktop function. Treat it as developer-facing and client-only. The normal GUI path still uses the stable desktop open flow unless your addon is explicitly extending the web bridge.

## Mail

### `AE3_desktop_fnc_addEmail`

Adds an email to a laptop's `/var/mail` directory. It can target one laptop, a laptop `netId`, or `"all"`.

```sqf
[_target, _from, _subject, _body, _to, _receivedTime, _createFrom, _createTo] call AE3_desktop_fnc_addEmail;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | Object/String | Required | Laptop object, laptop netId, or `"all"`. |
| `1` | String | Required | Sender. |
| `2` | String | Required | Subject. |
| `3` | String | Required | Body. Use `endl` for line breaks. |
| `4` | String | `""` | Recipient. |
| `5` | String | `""` | Received time `HH:MM`; blank uses current time. |
| `6` | Bool | `false` | Add sender to mission address book. |
| `7` | Bool | `false` | Add recipient to mission address book. |

Example:

```sqf
[
    _laptop,
    "informant@lan",
    "Convoy schedule",
    "They move at 0400." + endl + "Route marker is in the browser history.",
    "admin@lan",
    "02:17",
    true,
    true
] call AE3_desktop_fnc_addEmail;
```

The function is server-side and routes from clients. Open terminal/desktop users may receive a notification.

## Calendar Content

### `AE3_desktop_fnc_addCalendarEvent`

Adds a text calendar entry to the laptop filesystem.

```sqf
[_target, _date, _title, _details] call AE3_desktop_fnc_addCalendarEvent;
```

Example:

```sqf
[_laptop, "2026-06-30 04:00", "Convoy departs", "Route Red, three trucks"] call AE3_desktop_fnc_addCalendarEvent;
```

Use this when you want an entry to be readable from the Files app or terminal. Use `AE3_armaos_fnc_computer_addCalendarEvent` when you want structured `AE3_calendar_events` state.

## Media

### `AE3_desktop_fnc_registerMedia`

Registers an image, video, or audio asset and creates a marker file in laptop filesystems.

```sqf
[_sourcePath, _type, _fsDest, _targets, _scope, _web] call AE3_desktop_fnc_registerMedia;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | String | Required | Real mission/mod path to the asset. |
| `1` | String | Required | `"image"`, `"video"`, or `"audio"`. |
| `2` | String | Required | Virtual filesystem destination. |
| `3` | Array/String | `"all"` | Array of laptops, `"all"`, or `"future"`. |
| `4` | String | `"auto"` | `"mission"`, `"mod"`, or `"auto"`. |
| `5` | Bool | `false` | Try web image viewer first for images. |

Examples:

```sqf
["media\images\safehouse.jpg", "image", "/home/admin/Desktop/safehouse.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;
["\my_mod\data\briefing.ogv", "video", "/home/admin/Desktop/briefing.ogv", "all", "mod"] call AE3_desktop_fnc_registerMedia;
["music\intercept.ogg", "audio", "/home/admin/Desktop/intercept.ogg", "future", "mission"] call AE3_desktop_fnc_registerMedia;
```

Notes:

- `"future"` is useful for addon-level media that should appear on laptops initialized later.
- The created file is a marker, not a copy of the binary media.
- Server holds the registry and target filesystem state.

## Locked Files

### `AE3_desktop_fnc_addLockedFile`

Creates a password-protected file that can be unlocked from the GUI Files app or the terminal `unlock` command.

```sqf
[_target, _path, _password, _content, _owner, _permissions] call AE3_desktop_fnc_addLockedFile;
```

Example:

```sqf
[
    _laptop,
    "/home/admin/Desktop/codes.txt",
    "hunter2",
    "Launch code: 7741",
    "admin",
    [[true, true, false], [true, false, false]]
] call AE3_desktop_fnc_addLockedFile;
```

The protected content may itself be a media marker if you want a locked image/video/audio file.

## CCTV

### `AE3_desktop_fnc_registerCamera`

Registers an object as a CCTV camera source for the desktop CCTV app.

```sqf
[_name, _object, _offset, _dir] call AE3_desktop_fnc_registerCamera;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | String | Required | Camera name shown in the app. |
| `1` | Object | Required | Object the camera view originates from. |
| `2` | Array | `[0, 0.2, 0.1]` | Model-space camera offset. |
| `3` | Number | Object direction | View direction in degrees. |

Example:

```sqf
["Compound Gate", _cameraProp, [0, 0.25, 0.15], 180] call AE3_desktop_fnc_registerCamera;
```

Rendering is client-local when a player opens the app. The registry is shared.

## Native Desktop Apps

### `AE3_desktop_fnc_registerApp`

Registers a native SQF desktop app at runtime.

```sqf
[_className, _displayName, _entry, _size, _showOnDesktop, _singleton] call AE3_desktop_fnc_registerApp;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | String | Required | Unique app id. |
| `1` | String | Required | Name shown on icon/window. |
| `2` | String | Required | Function name resolved from `missionNamespace`. |
| `3` | Array | `[0.5, 0.5]` | Window size as a fraction of desktop space. |
| `4` | Bool | `true` | Show launcher on desktop. |
| `5` | Bool | `true` | Allow only one open instance. |

Example:

```sqf
if (hasInterface) then {
    ["myMod_hackTool", "Hack Tool", "myMod_fnc_hackToolApp", [0.6, 0.6], true, true] call AE3_desktop_fnc_registerApp;
};
```

Entry function contract:

```sqf
params ["_winId", "_ctrlGroup", "_computer", "_args"];

// Build controls inside _ctrlGroup.

createHashMapFromArray [
    ["onClose", {
        // Optional cleanup.
    }]
]
```

Registration is local to clients. Run it in client init or addon pre/post init on every client that should see the app.

## Web Desktop Bridge

### `AE3_desktop_fnc_registerExtApp`

Registers an external web desktop app template entry. This is for addons extending the web desktop bridge without AE3 depending on them.

```sqf
[_id, _title, _glyph, _kind, _extra] call AE3_desktop_fnc_registerExtApp;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | String | Required | Unique app id. |
| `1` | String | Required | Display title. |
| `2` | String | Required | Glyph/icon text passed to JS. |
| `3` | String | `"deviceList"` | Template kind. |
| `4` | HashMap | Empty | Extra data passed to JS. Optional `requiresVar` filter. |

Example:

```sqf
if (hasInterface) then {
    private _extra = createHashMapFromArray [
        ["deviceType", "doorRelay"],
        ["requiresVar", ["myMod_hasDoorTools", true]]
    ];

    ["myMod_doors", "Door Relays", "D", "deviceList", _extra] call AE3_desktop_fnc_registerExtApp;
};
```

### `AE3_desktop_fnc_registerCmd`

Registers a SQF handler for a custom JS command.

```sqf
[_cmd, _code] call AE3_desktop_fnc_registerCmd;
```

Handler contract:

```sqf
params ["_computer", "_user", "_data", "_rid"];
```

Example:

```sqf
if (hasInterface) then {
    ["myMod_scanDoors", {
        params ["_computer", "_user", "_data", "_rid"];

        private _doors = missionNamespace getVariable ["myMod_knownDoors", []];
        ["myMod_scanDoors", _rid, _doors] call AE3_desktop_fnc_jsReply;
    }] call AE3_desktop_fnc_registerCmd;
};
```

### `AE3_desktop_fnc_jsReply`

Resolves one JS request by request id.

```sqf
[_command, _rid, _payload] call AE3_desktop_fnc_jsReply;
```

Use this inside `registerCmd` handlers for immediate replies. If `_rid` is empty, the function no-ops.

## Related Pages

- [Desktop Apps](Desktop-Apps.md)
- [Browser API](Browser-API.md)
- [Filesystem API](Filesystem-API.md)
- [Extending Desktop GUI](../Developer/Extending-Desktop-GUI.md)
- [Extending Browser Webpages](../Developer/Extending-Browser-Webpages.md)

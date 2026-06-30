# Desktop API

The desktop API covers GUI apps, interface mode/access, mail, media, calendar, CCTV, locked files, browser pages, and web-desktop extension hooks.

## Interface Access

| Function | Arguments | Purpose |
| --- | --- | --- |
| `AE3_desktop_fnc_setInterfaceMode` | `[laptop, mode]` | Set `cli`, `gui`, or `both`. |
| `AE3_desktop_fnc_setInterfaceAccess` | `[laptop, "cli" or "gui", condition]` | Set access by code, UID list, or side list. |
| `AE3_desktop_fnc_canAccessInterface` | `[laptop, player, "cli" or "gui"]` | Return whether access is allowed. |

```sqf
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
```

## Desktop Content

| Function | Purpose |
| --- | --- |
| `AE3_desktop_fnc_addEmail` | Add mail under `/var/mail`. |
| `AE3_desktop_fnc_registerMedia` | Add image, video, or audio marker files. |
| `AE3_desktop_fnc_addLockedFile` | Add a password-protected file. |
| `AE3_desktop_fnc_addCalendarEvent` | Add GUI calendar data. |
| `AE3_desktop_fnc_registerCamera` | Register a camera for the CCTV app. |

```sqf
[_laptop, "HQ", "Orders", "Hold until 0500.", "admin@lan"] call AE3_desktop_fnc_addEmail;
[_laptop, "2028-05-14", "Meet contact", "Old radio tower"] call AE3_desktop_fnc_addCalendarEvent;
["Gate Cam", _cameraObject] call AE3_desktop_fnc_registerCamera;
```

## App Extension

| Function | Purpose |
| --- | --- |
| `AE3_desktop_fnc_registerApp` | Register a local SQF desktop app. |
| `AE3_desktop_fnc_registerExtApp` | Register a web-desktop external app template. |
| `AE3_desktop_fnc_registerCmd` | Register a JS-to-SQF command handler. |
| `AE3_desktop_fnc_openFile` | Open content in the desktop file/media viewer. |

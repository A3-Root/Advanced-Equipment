# Desktop GUI

The desktop GUI is the graphical operating system for AE3 laptops. It provides a window manager, app launcher, taskbar behavior, authentication, filesystem access, network-aware apps, browser pages, media viewers, settings, and app extension points.

## Built-In Apps

- Terminal
- Files
- Settings
- Notepad
- Mail
- Chat
- Browser
- Calendar
- Map
- CCTV
- Music
- SysInfo

The app registry is defined in `CfgAE3Apps` and can be extended through config or runtime registration.

## Access

GUI access is controlled separately from TUI access:

```sqf
[_laptop, "gui"] call AE3_desktop_fnc_setInterfaceMode;
[_laptop, "gui", [west, "76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;
```

## Files and Locked Files

The Files app reads the AE3 filesystem. Passworded files can be unlocked through the GUI prompt or through the TUI `unlock` command.

## Extension Points

- Add apps with `CfgAE3Apps` or `AE3_desktop_fnc_registerApp`.
- Add web-desktop command handlers with `AE3_desktop_fnc_registerCmd`.
- Register browser pages with `AE3_desktop_fnc_registerWebpage`.
- Seed mail, media, history, and locked files through the desktop API.

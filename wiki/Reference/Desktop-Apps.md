# Desktop Apps

The built-in GUI app registry is `CfgAE3Apps`.

| App Class | Entry Function | Purpose |
| --- | --- | --- |
| `Terminal` | `AE3_desktop_fnc_app_terminal` | Terminal in a desktop window. |
| `Files` | `AE3_desktop_fnc_app_files` | Browse and open filesystem content. |
| `Settings` | `AE3_desktop_fnc_app_settings` | Laptop/desktop settings. |
| `Notepad` | `AE3_desktop_fnc_app_notepad` | Text note workflow. |
| `Mail` | `AE3_desktop_fnc_app_mail` | Read seeded mail. |
| `Chat` | `AE3_desktop_fnc_app_chat` | Network chat. |
| `Browser` | `AE3_desktop_fnc_app_browser` | Browse registered webpages. |
| `Calendar` | `AE3_desktop_fnc_app_calendar` | Show calendar events. |
| `MapApp` | `AE3_desktop_fnc_app_map` | Map app. |
| `Cctv` | `AE3_desktop_fnc_app_cctv` | Camera viewing. |
| `Music` | `AE3_desktop_fnc_app_music` | Audio playback. |
| `SysInfo` | `AE3_desktop_fnc_app_sysinfo` | Device and system data. |

## Runtime Registration

```sqf
["my_app", "My App", "myTag_fnc_myDesktopApp", [0.6, 0.6], true, true] call AE3_desktop_fnc_registerApp;
```

The entry function is called with:

```sqf
params ["_winId", "_ctrlGroup", "_computer", "_args"];
```

It may return a hashmap containing callbacks such as `onClose` or `onFocus`.

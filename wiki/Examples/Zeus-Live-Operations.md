# Zeus Live Operations

Zeus can add or change AE3 content during play through modules and device actions.

## Live Intel Drop

1. Select or place a laptop.
2. Add a webpage or email module.
3. Add browser history pointing to the webpage.
4. Optionally restrict GUI or TUI access to the intended player group.

Script equivalent:

```sqf
["intel.root/live", "Live Drop", "Move to the radio tower.", _laptop] call AE3_desktop_fnc_registerWebpage;
[_laptop, "intel.root/live", "now"] call AE3_desktop_fnc_addHistoryEntry;
```

## Emergency Device Control

```sqf
[_laptop] call AE3_power_fnc_crashDevice;
[_router] call AE3_power_fnc_turnOffDevice;
[_generator] call AE3_power_fnc_turnOnDevice;
```

Use the Zeus filesystem browser for small live edits. For repeatable mission behavior, prefer scripted setup in init files or modules.

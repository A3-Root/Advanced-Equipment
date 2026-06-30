# Laptops and Interfaces

AE3 laptops are interactive ACE equipment with power, filesystem, user, USB, network, GUI desktop, and TUI terminal behavior.

## Interface Modes

The desktop addon stores the active interface mode in `AE3_interfaceMode`.

- `cli`: terminal/TUI only.
- `gui`: graphical desktop only.
- `both`: exposes both access actions when allowed.

```sqf
[_laptop, "cli"] call AE3_desktop_fnc_setInterfaceMode;
[_laptop, "gui"] call AE3_desktop_fnc_setInterfaceMode;
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
```

## Access Conditions

GUI and TUI can have separate access conditions.

```sqf
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "cli", ["76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "gui", {(_this select 1) getVariable ["hasKeycard", false]}] call AE3_desktop_fnc_setInterfaceAccess;
```

The access hook is:

```sqf
if ([_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface) then {
    // show or open GUI-specific behavior
};
```

## Choosing GUI or TUI

Use GUI desktop for document review, browser pages, media, mail, calendar entries, app workflows, and non-command-line players. Use TUI terminal for hacking-style gameplay, commands, SSH, logs, USB mounting, file permissions, custom command puzzles, and compact interactions.

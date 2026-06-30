# Configure GUI vs TUI Access

## GUI Only

```sqf
[_laptop, "gui"] call AE3_desktop_fnc_setInterfaceMode;
```

## TUI Only

```sqf
[_laptop, "cli"] call AE3_desktop_fnc_setInterfaceMode;
```

## Both Interfaces

```sqf
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
```

## Separate Access Rules

```sqf
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "cli", [east, "76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;
```

## Keycard-Style Access

```sqf
[_laptop, "gui", {
    params ["_laptop", "_player"];
    _player getVariable ["AE3_hasGuiKeycard", false]
}] call AE3_desktop_fnc_setInterfaceAccess;
```

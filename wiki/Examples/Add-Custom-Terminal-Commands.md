# Add Custom Terminal Commands

Custom commands are useful for mission puzzles and fake utilities.

```sqf
[_laptop, "uplink", "/bin/uplink", {
    params ["_computer", "_options", "_commandName"];

    private _router = _computer getVariable ["AE3_network_parent", objNull];
    if (isNull _router) exitWith {
        [_computer, "No router connected."] call AE3_armaos_fnc_shell_stdout;
    };

    [_computer, "Uplink active."] call AE3_armaos_fnc_shell_stdout;
}, "Check network uplink", "uplink: prints router connection state"] call AE3_armaos_fnc_computer_addCustomCommand;
```

Run it from the terminal:

```text
uplink
```

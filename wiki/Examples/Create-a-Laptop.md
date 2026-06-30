# Create a Laptop

Place an AE3 laptop in 3DEN, then configure its interface and content.

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "admin", "admin123"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, true, false] call AE3_armaos_fnc_computer_addSecurityCommands;

    [_laptop, "HQ", "Welcome", "Check Browser history.", "admin@lan"] call AE3_desktop_fnc_addEmail;
    ["intel.root/start", "Start Page", "Look for the fuel depot.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/start", "01:14"] call AE3_desktop_fnc_addHistoryEntry;
};
```

Use GUI for Browser/Mail/Files inspection and TUI for commands such as `cat`, `ssh`, `ping`, and `unlock`.

# Add Users and Passwords

```sqf
if (isServer) then {
    [_laptop, "admin", "admin123"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "guest", "guest"] call AE3_armaos_fnc_computer_addUser;
};
```

Each user gets a home directory at `/home/<username>`.

## Minimal Command Set

```sqf
[_laptop, ["ls", "cd", "cat", "ip", "ping", "ssh"], false, false, []] call AE3_armaos_fnc_computer_initWithCommands;
```

## Add Security Commands

```sqf
[_laptop, true, true] call AE3_armaos_fnc_computer_addSecurityCommands;
```

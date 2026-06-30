# Encryption and Security

AE3 includes optional security commands and encrypted/locked content for puzzle design.

## Commands

Security commands are configured in `CfgSecurityCommands`:

- `crypto`
- `crack`

Add them to a laptop:

```sqf
[_laptop, true, true] call AE3_armaos_fnc_computer_addSecurityCommands;
```

## Locked Files

Passworded files are usually the clearest mission-facing security primitive:

```sqf
[_laptop, "/home/admin/secure.txt", "falcon", "Safehouse grid 043072"] call AE3_desktop_fnc_addLockedFile;
```

## File Permissions

Use filesystem permissions for ownership puzzles and for limiting what non-root users can read, write, or execute.

```sqf
private _ownerOnly = [[true, true, false], [false, false, false]];
[[], _filesystem, "/root/private.txt", "secret", "root", "root", _ownerOnly] call AE3_filesystem_fnc_createFile;
```

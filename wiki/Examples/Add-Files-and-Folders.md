# Add Files and Folders

## Direct Filesystem Setup

```sqf
if (isServer) then {
    private _fs = _laptop getVariable ["AE3_filesystem", []];
    private _dirPerms = [[true, true, true], [true, false, true]];
    private _filePerms = [[true, true, false], [true, false, false]];

    [[], _fs, "/home/admin/intel", "root", "admin", _dirPerms] call AE3_filesystem_fnc_createDir;
    [[], _fs, "/home/admin/intel/orders.txt", "Move at dawn.", "root", "admin", _filePerms] call AE3_filesystem_fnc_createFile;

    _laptop setVariable ["AE3_filesystem", _fs, true];
};
```

The file is visible in the GUI Files app and readable in TUI:

```text
cat /home/admin/intel/orders.txt
```

## Locked File

```sqf
[_laptop, "/home/admin/intel/safe.txt", "falcon", "Cache at grid 040071"] call AE3_desktop_fnc_addLockedFile;
```

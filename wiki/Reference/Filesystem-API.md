# Filesystem API

Filesystem calls operate on a pointer, filesystem array, path, and user. Object-level helpers such as desktop intel APIs are easier for mission setup; use direct filesystem calls when building framework extensions.

## Core Calls

| Function | Purpose |
| --- | --- |
| `AE3_filesystem_fnc_createDir` | Create a directory. |
| `AE3_filesystem_fnc_createFile` | Create a file with content, owner, and permissions. |
| `AE3_filesystem_fnc_writeToFile` | Replace or append file content. |
| `AE3_filesystem_fnc_getFile` | Read a file after checking permission. |
| `AE3_filesystem_fnc_mvObj` | Move or rename an object. |
| `AE3_filesystem_fnc_delObj` | Delete an object. |
| `AE3_filesystem_fnc_chdir` | Resolve a working directory change. |
| `AE3_filesystem_fnc_lsdir` | List a directory. |
| `AE3_filesystem_fnc_chown` | Change owner. |
| `AE3_filesystem_fnc_chmod` | Change permissions. |
| `AE3_filesystem_fnc_symlink` | Create a symlink marker. |
| `AE3_filesystem_fnc_mount` | Mount another filesystem at a path. |
| `AE3_filesystem_fnc_unmount` | Remove a mount. |

## Example

```sqf
private _fs = _laptop getVariable ["AE3_filesystem", []];
private _perms = [[true, true, false], [true, false, false]];

[[], _fs, "/home/admin", "root", "admin"] call AE3_filesystem_fnc_createDir;
[[], _fs, "/home/admin/orders.txt", "Move at dawn.", "root", "admin", _perms] call AE3_filesystem_fnc_createFile;

_laptop setVariable ["AE3_filesystem", _fs, true];
```

## Permissions

`0` is read, `1` is write, and `2` is execute when a function asks for a permission index.

# Filesystem

AE3 devices use a virtual filesystem stored on the object. It supports directories, files, owners, read/write/execute permissions, symbolic links, mounts, and flash drive filesystems.

## Default Layout

The base filesystem includes paths such as:

- `/tmp`
- `/mnt`
- `/var`
- `/var/log`
- `/etc`
- `/home`
- `/bin`
- `/sbin`
- `/root`
- `/sys`

## Permissions

Permissions are stored as:

```sqf
[[ownerRead, ownerWrite, ownerExecute], [everyoneRead, everyoneWrite, everyoneExecute]]
```

Example:

```sqf
private _readOnly = [[true, true, false], [true, false, false]];
[[], _filesystem, "/home/admin/readme.txt", "Read this first.", "root", "admin", _readOnly] call AE3_filesystem_fnc_createFile;
```

## GUI and TUI

The GUI Files app and TUI commands operate on the same filesystem. A file added for the terminal is visible in the desktop Files app, and a browser history file can be inspected with `cat /var/log/browser_history`.

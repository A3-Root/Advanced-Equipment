# Filesystem API

The Filesystem component provides a small Unix-like virtual filesystem used by both the terminal and desktop GUI. Mission scripts can use it directly, but higher-level APIs such as `AE3_desktop_fnc_addEmail`, `AE3_desktop_fnc_registerWebpage`, `AE3_desktop_fnc_registerMedia`, and `AE3_armaos_fnc_computer_addUser` are usually safer for mission content.

Use direct filesystem calls when you are building framework extensions, creating custom command files, manipulating permissions, or writing content that has no higher-level helper.

## Filesystem Object Format

A filesystem object is:

```sqf
[content, owner, permissions]
```

| Field | Type | Meaning |
| --- | --- | --- |
| `content` | HashMap, String, Code, or marker content | Directories use a HashMap. Files use the value that apps or commands will read. |
| `owner` | String | Owner username. `root` bypasses most ownership checks. |
| `permissions` | Array | `[[ownerR, ownerW, ownerX], [everyoneR, everyoneW, everyoneX]]`. |

The root filesystem stored on a laptop is also a filesystem object:

```sqf
private _filesystem = _laptop getVariable ["AE3_filesystem", []];
```

Most functions mutate `_filesystem` in place. If you manually retrieved it from a laptop, publish it after the changes:

```sqf
_laptop setVariable ["AE3_filesystem", _filesystem, true];
```

For laptop-locality-aware publishing, use the same target pattern used by the surrounding component when available. Most mission init scripts can use `true`.

## Common Arguments

Most low-level calls share these parameters:

| Argument | Type | Meaning |
| --- | --- | --- |
| `_pntr` | Array | Current directory pointer, for example `[]` for root or `["home", "admin"]`. Use `[]` when passing absolute paths. |
| `_filesystem` | Array | Filesystem object to mutate/read. |
| `_target` | String | Absolute or relative virtual path. |
| `_user` | String | User performing the operation. Affects permissions and `~` resolution. |
| `_owner` | String | Owner assigned to newly created content. |
| `_permissions` | Array | Permission tuple. |

Permission indexes:

| Index | Meaning |
| --- | --- |
| `0` | Read |
| `1` | Write |
| `2` | Execute |

## Creating Directories

### `AE3_filesystem_fnc_createDir`

Creates a directory. Throws if the directory already exists.

```sqf
[_pntr, _filesystem, _target, _user, _owner, _permissions] call AE3_filesystem_fnc_createDir;
```

Arguments:

| Index | Type | Required | Meaning |
| --- | --- | --- | --- |
| `0` | Array | Yes | Current pointer. |
| `1` | Array | Yes | Filesystem object. |
| `2` | String | Yes | Directory path. |
| `3` | String | Yes | User creating the directory. |
| `4` | String | Optional | New directory owner. Defaults to `_user`. |
| `5` | Array | Optional | Defaults to owner `rwx`, everyone none. |

Example:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";

[[], _fs, "/home/admin/intel", "root", "admin", [[true, true, true], [true, false, true]]] call AE3_filesystem_fnc_createDir;

_laptop setVariable ["AE3_filesystem", _fs, true];
```

### `AE3_filesystem_fnc_ensureDir`

Creates a directory only if it is missing. Returns `true` when created and `false` when it already existed. Other exceptions are rethrown.

```sqf
private _created = [[], _fs, "/var/log", "root"] call AE3_filesystem_fnc_ensureDir;
```

Use this in repeatable mission initialization scripts because preview restarts and JIP repair scripts may run more than once.

## Creating Files

### `AE3_filesystem_fnc_createFile`

Creates a file with content. Throws if the file already exists.

```sqf
[_pntr, _filesystem, _target, _content, _user, _owner, _permissions] call AE3_filesystem_fnc_createFile;
```

Default file permissions are owner read/write, everyone none.

Example:

```sqf
private _perms = [[true, true, false], [true, false, false]];
[[], _fs, "/home/admin/orders.txt", "Move at dawn.", "root", "admin", _perms] call AE3_filesystem_fnc_createFile;
```

Files can contain strings, code, media markers, locked-file payloads, symlink markers, or other structured values expected by a custom app. For normal text intel, use strings.

### `AE3_filesystem_fnc_ensureFile`

Creates a file only if it is missing. Returns `true` when created and `false` when it already existed.

```sqf
[[], _fs, "/var/mail/inbox", "", "root"] call AE3_filesystem_fnc_ensureFile;
```

Use `ensureFile` before appending to a log-like file.

## Reading and Writing Files

### `AE3_filesystem_fnc_getFile`

Reads file content after checking the requested permission.

```sqf
private _content = [_pntr, _filesystem, _target, _user, _permission] call AE3_filesystem_fnc_getFile;
```

Example:

```sqf
private _orders = [[], _fs, "/home/admin/orders.txt", "admin", 0] call AE3_filesystem_fnc_getFile;
```

The return value is whatever was stored in the file. Do not assume it is a string unless you control the file.

### `AE3_filesystem_fnc_writeToFile`

Replaces or appends string content. Requires write permission on the file.

```sqf
[_pntr, _filesystem, _target, _user, _content, _appendMode] call AE3_filesystem_fnc_writeToFile;
```

Example:

```sqf
[[], _fs, "/var/log/custom.log", "root", "Laptop seeded." + endl, true] call AE3_filesystem_fnc_writeToFile;
```

`_appendMode` defaults to `false`. Pass `true` for logs, browser history, chat logs, or mail-like append behavior.

## Listing and Searching

### `AE3_filesystem_fnc_lsdir`

Lists a directory and returns terminal-formatted entries.

```sqf
private _entries = [[], _fs, "/home/admin", "admin", true] call AE3_filesystem_fnc_lsdir;
```

The final boolean enables long listing with owner/permission details.

### `AE3_filesystem_fnc_findFilesystemObject`

Recursively searches for an exact object name.

```sqf
private _result = [[], _fs, "admin", "orders.txt"] call AE3_filesystem_fnc_findFilesystemObject;
_result params ["_paths", "_missingPermissionCount"];
```

Use this for developer tooling or UI search. It respects read permissions and reports how many directories were skipped because the user could not read them.

## Moving, Copying, and Deleting

### `AE3_filesystem_fnc_mvObj`

Moves or copies a file or directory.

```sqf
[_pntr, _filesystem, _source, _target, _user, _copy] call AE3_filesystem_fnc_mvObj;
```

Example:

```sqf
[[], _fs, "/tmp/orders.txt", "/home/admin/orders.txt", "root"] call AE3_filesystem_fnc_mvObj;
[[], _fs, "/home/admin/orders.txt", "/backup/orders.txt", "root", true] call AE3_filesystem_fnc_mvObj;
```

`_copy` defaults to `false`. Copying requires read permission on the source. Moving requires write permission on the source and target directory.

### `AE3_filesystem_fnc_delObj`

Deletes a file or directory.

```sqf
[[], _fs, "/tmp/old.txt", "root"] call AE3_filesystem_fnc_delObj;
```

## Ownership and Permissions

### `AE3_filesystem_fnc_chown`

Changes owner. Root or the current owner can change ownership.

```sqf
[[], _fs, "/home/admin/intel", "root", "admin", true] call AE3_filesystem_fnc_chown;
```

The final boolean applies recursively when the target is a directory.

### `AE3_filesystem_fnc_chmod`

Changes permissions. Root can change any object; non-root users can change only objects they own.

```sqf
private _readOnlyForEveryone = [[true, true, false], [true, false, false]];
[[], _fs, "/home/admin/orders.txt", "admin", _readOnlyForEveryone] call AE3_filesystem_fnc_chmod;
```

Recursive directory update:

```sqf
[[], _fs, "/home/admin/intel", "root", [[true, true, true], [true, false, true]], true] call AE3_filesystem_fnc_chmod;
```

## Symlinks and Desktop Launchers

### `AE3_filesystem_fnc_symlink`

Creates a symlink marker file pointing at an absolute target path.

```sqf
[[], _fs, "/home/admin/Desktop/terminal.app", "/usr/share/applications/terminal.app", "admin"] call AE3_filesystem_fnc_symlink;
```

The desktop uses `.app` launcher files and symlinks to populate each user's Desktop. If you are curating a laptop GUI, you can copy or symlink launchers from `/usr/share/applications` into `/home/<user>/Desktop`.

## Mounts

### `AE3_filesystem_fnc_mount`

Mounts another filesystem into an existing mount point.

```sqf
[[], _hostFs, _flashdriveFs, "/mnt/usb0", "root"] call AE3_filesystem_fnc_mount;
```

### `AE3_filesystem_fnc_unmount`

Unmounts a filesystem from a mount point.

```sqf
[[], _hostFs, _flashdriveFs, "/mnt/usb0", "root"] call AE3_filesystem_fnc_unmount;
```

Mission scripts rarely need these directly. Prefer `AE3_flashdrive_fnc_mount` and `AE3_flashdrive_fnc_unmount` for USB devices because those functions also update laptop and flash drive object state.

## Idempotent Laptop Content Example

This example creates a repeatable setup block for one laptop:

```sqf
if (isServer) then {
    private _fs = _laptop getVariable "AE3_filesystem";
    private _dirPerms = [[true, true, true], [true, false, true]];
    private _filePerms = [[true, true, false], [true, false, false]];

    [[], _fs, "/home/admin/intel", "root", "admin", _dirPerms] call AE3_filesystem_fnc_ensureDir;
    [[], _fs, "/home/admin/intel/orders.txt", "Orders pending.", "root", "admin", _filePerms] call AE3_filesystem_fnc_ensureFile;
    [[], _fs, "/home/admin/intel/orders.txt", "root", "Move at 0430." + endl, false] call AE3_filesystem_fnc_writeToFile;

    _laptop setVariable ["AE3_filesystem", _fs, true];
};
```

## Common Failure Points

| Symptom | Likely cause |
| --- | --- |
| Duplicate path exception | Use `ensureDir`/`ensureFile` or delete the object before recreating it. |
| Permission exception | The `_user` argument does not own the file and everyone permission is not enough. Use `root` for setup scripts. |
| File appears on server but not client | The edited filesystem was not published back to the laptop, or publication used the wrong target locality. |
| GUI app cannot open file | The file content is not the marker or launcher format that app expects. |
| Mounted drive changes disappear | The flash drive object filesystem was not updated during unmount. Use Flashdrive API instead of direct mount calls. |

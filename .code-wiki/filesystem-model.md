---
topic: filesystem-model
status: verified
last-verified: 2026-06-30
confidence_score: 1.0
priority: core
rank: 7
tokens: ~720
code-paths:
  - addons/filesystem/
  - addons/desktop/functions/fnc_fsHandle.sqf
related-topics: [armaos-terminal, desktop-gui-and-browser, flashdrive-usb, eden-zeus-tooling, desktop-intel-and-communications, multiplayer-locality-and-sync]
related-docs:
  - wiki/Systems/Filesystem.md
  - wiki/Reference/Filesystem-API.md
---

# Filesystem Model

## overview

The filesystem component implements AE3's virtual Unix-like filesystem for laptops and flash drives, including directories, files, permissions, owners, symlinks, mounts, search, and editor/Zeus content insertion.

## current behavior

- Filesystems are stored as nested arrays/hashmaps on an object variable named `AE3_filesystem`.
- `AE3_filesystem_fnc_initFilesystem` creates the root filesystem and optionally seeds config-defined `AE3_FilesystemObject` entries.
- Filesystem pointers are arrays representing the current path; laptops also store `AE3_filepointer`.
- Permissions are two triples: owner permissions and other-user permissions. Functions convert config numeric permissions into booleans during initialization.
- Root bypass is enforced by the core permission check itself. The desktop file handler also normalizes `admin` to filesystem user `root`, while normal users operate under their account name.
- CLI and GUI operations share core functions such as `createFile`, `createDir`, `ensureFile`, `ensureDir`, `getFile`, `writeToFile`, `mvObj`, `delObj`, `chmod`, `chown`, `symlink`, `mount`, and `unmount`.
- Desktop delete behavior moves objects to `/.trash` and tracks original paths in `AE3_trash_meta`; CLI delete may use direct filesystem deletion depending on the command.
- Mission/editor modules use wrapper functions such as `device_addFile`, `device_addDir`, `module_addFile`, and `module_addDir`.

## decisions

- The filesystem is object-local state rather than global state, so each laptop and flash drive can carry independent files, permissions, and mounts.
- Config seeding and script insertion share the same creation functions, so content added by addon config, Eden modules, Zeus modules, and scripts produces the same internal objects.
- Desktop file operations call the core filesystem API instead of maintaining a separate GUI model, preventing GUI/TUI permission drift.
- Symlinks are stored as file content that resolves to a target path, avoiding a third object type in the filesystem structure.

## gotchas

- `AE3_filesystem` can be missing or still syncing on clients.
- Locality and sync mode matter after mutation. CLI commands and device add functions read `AE3_Filesystem_SyncMode`; desktop mutating operations often broadcast `AE3_filesystem` to target 2.
- Permission checks are caller-sensitive except for core root bypass. A function may permit or deny based on the `_user` argument supplied by CLI, desktop, Zeus, or script.
- Existing-object collisions during config seeding are skipped only when the exception matches the localized already-exists string.

## re-verify when

- Filesystem object structure changes.
- Permission representation changes.
- Desktop or terminal file operation wrappers change.
- Flash drive mount behavior changes.

## references

- `addons/filesystem/functions/fnc_initFilesystem.sqf`
- `addons/filesystem/functions/fnc_createFile.sqf`
- `addons/filesystem/functions/fnc_createDir.sqf`
- `addons/filesystem/functions/fnc_hasPermission.sqf`
- `addons/filesystem/functions/fnc_mount.sqf`
- `addons/desktop/functions/fnc_fsHandle.sqf`


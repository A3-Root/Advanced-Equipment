# Debugging

Use this page when an AE3 feature works in a simple editor preview but fails in multiplayer, dedicated server, Zeus, Eden module setup, GUI/TUI use, networking, power, or flash-drive workflows.

## Required Validation

For code changes, final validation must pass:

```sh
hemtt check -p -Lc14 -e
```

This validates configs, SQF compilation, stringtables, and project style according to the repository's HEMTT setup.

For docs-only changes, run Markdown/link checks when available and use `rg` to confirm function names, module names, and paths exist.

## Fast Triage

Start with the system that owns the symptom:

| Symptom | First area to inspect |
| --- | --- |
| Player cannot open laptop | Power, interaction state, interface mode/access, mutex. |
| GUI opens but app missing | Desktop app registration, user Desktop launchers, CBA desktop settings. |
| Terminal command missing | ArmaOS command links, command install setup, filesystem execute permission. |
| File missing | Filesystem path, setup locality, module sync, owner/permissions. |
| Browser page missing | Page registration target, history vs page distinction. |
| Email/media missing | Desktop content API target and server timing. |
| Ping/SSH fails | Power, router links, IPs, external access policy. |
| Flash drive content missing | USB occupied state, mount state, unmount saving, server publication. |
| Zeus module does nothing | Synced/selected object, server execution, module activation. |

## Inspecting Object Variables

In debug console, inspect common variables:

```sqf
_laptop getVariable ["AE3_filesystem", nil];
_laptop getVariable ["AE3_Userlist", createHashMap];
_laptop getVariable ["AE3_Links", createHashMap];
_laptop getVariable ["AE3_interfaceMode", "default"];
_laptop getVariable ["AE3_power_powerState", -1];
_laptop getVariable ["AE3_network_ip", []];
_laptop getVariable ["AE3_network_parent", objNull];
_laptop getVariable ["AE3_USB_Interfaces", createHashMap];
_laptop getVariable ["AE3_USB_Interfaces_occupied", []];
_laptop getVariable ["AE3_USB_Interfaces_mounted", []];
```

On dedicated servers, run state-changing diagnostics on the server when possible. Client debug console may show stale or local-only values if state was not published.

## GUI/TUI Access Checks

Checklist:

1. Laptop has initialized filesystem.
2. Laptop has power or internal battery charge.
3. Laptop is turned on or can be turned on.
4. Laptop is not locked by `AE3_computer_mutex`.
5. Interface mode allows the interface being opened.
6. Interface access condition allows the current player.
7. ACE interactions are present and not hidden by interaction state.

Useful check:

```sqf
[_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface;
[_laptop, player, "cli"] call AE3_desktop_fnc_canAccessInterface;
```

## Filesystem Debugging

Read a file directly:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
private _content = [[], _fs, "/home/admin/orders.txt", "admin", 0] call AE3_filesystem_fnc_getFile;
```

List a directory:

```sqf
private _entries = [[], _fs, "/home/admin", "admin", true] call AE3_filesystem_fnc_lsdir;
```

Common filesystem issues:

| Issue | Fix |
| --- | --- |
| Duplicate object exception | Use `ensureFile`/`ensureDir` for repeatable setup. |
| Permission exception | Use correct user or setup as `root`; check permission tuple. |
| Content only exists locally | Publish `AE3_filesystem` back to the laptop. |
| GUI cannot open file | File content may not match expected marker/app format. |

## Terminal Command Debugging

Check command link map:

```sqf
_laptop getVariable ["AE3_Links", createHashMap];
```

Check command file:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
[[], _fs, "/bin/myCommand", "root", 2] call AE3_filesystem_fnc_getFile;
```

If the command is not listed by `help`, it was not linked. If it is linked but fails to execute, inspect the command file permissions and code.

## Browser Debugging

Remember the split:

| Data | Where |
| --- | --- |
| Webpage registration | Browser registry / targeted laptop state. |
| Browser history | `/var/log/browser_history`. |

History entry without a registered page creates a clue but not a readable page.

Check history:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
[[], _fs, "/var/log/browser_history", "root", 0] call AE3_filesystem_fnc_getFile;
```

## Power Debugging

Check state:

```sqf
_device getVariable ["AE3_power_powerState", -1];
[_device] call AE3_power_fnc_getPowerState;
```

Check provider link:

```sqf
_laptop getVariable ["AE3_power_powerCableDevice", objNull];
```

Check fuel:

```sqf
[_generator] call AE3_power_fnc_getFuelLevel;
```

Check battery:

```sqf
private _battery = _laptop getVariable ["AE3_power_internal", objNull];
if (!isNull _battery) then {
    [_battery, true] call AE3_power_fnc_getBatteryLevel;
};
```

Common causes:

- Provider is off.
- Generator has no fuel.
- Battery is empty.
- Consumer draw exceeds provider output.
- Laptop is in use and cannot change state.
- Connection was made before devices initialized.

## Network Debugging

Check IP and parent:

```sqf
_laptop getVariable ["AE3_network_ip", []];
_laptop getVariable ["AE3_network_parent", objNull];
```

Resolve route:

```sqf
private _targetIp = ["10.0.0.12"] call AE3_network_fnc_str2ip;
private _result = [_laptop, _targetIp] call AE3_network_fnc_resolve;
_result params ["_target", "_length"];
```

If `_target` is `objNull`, check:

- Source laptop powered.
- Target laptop/router powered.
- Source has parent router.
- Target has IP.
- Router external policy if crossing gateways.
- Static IP duplicate failure.
- Physical network connection direction/setup.

Network route functions write more detail to the RPT when AE3 or network debug is enabled.

## Flash Drive Debugging

Check interfaces:

```sqf
_laptop getVariable ["AE3_USB_Interfaces", createHashMap];
_laptop getVariable ["AE3_USB_Interfaces_occupied", []];
_laptop getVariable ["AE3_USB_Interfaces_mounted", []];
```

Check mount path:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
[[], _fs, "/mnt/usb0", "root", true] call AE3_filesystem_fnc_lsdir;
```

If files disappear after removing a drive, verify that the drive was unmounted before conversion back to an inventory item.

## Zeus and Eden Module Debugging

For Eden modules:

- Module must be synced to the target laptop/object.
- Attributes must be saved on the module and the target object must be synced or selected correctly.
- Module execution order can matter when content depends on users/directories.
- Preview after saving the scenario to ensure attributes are serialized.

For Zeus modules:

- Curator must place the module on or sync/select a valid AE3 object.
- Server-side module functions need server execution.
- Some dialogs only apply after confirmation.
- Live changes may require open GUI/TUI refresh events.

## RPT Logging

Use `diag_log` for temporary diagnostics:

```sqf
diag_log format ["AE3 DEBUG: laptop=%1 fs=%2", _laptop, !isNil { _laptop getVariable "AE3_filesystem" }];
```

Remove temporary logs before submitting changes unless they are guarded by a debug setting or are valuable operational diagnostics.

## Final Review Checklist

Before handing off a change:

1. `hemtt check -p -Lc14 -e` passes for code changes.
2. No public function was added without Reference docs.
3. No user-facing workflow was changed without wiki guide updates.
4. Dedicated-server locality was considered.
5. JIP behavior was considered.
6. GUI/TUI/browser behavior was tested when touched.
7. Zeus/Eden behavior was tested when touched.
8. No ignored/read-only folders were modified.

## Related Pages

- [Architecture](Architecture.md)
- [Locality and Multiplayer](Locality-and-Multiplayer.md)
- [API Overview](../Reference/API-Overview.md)

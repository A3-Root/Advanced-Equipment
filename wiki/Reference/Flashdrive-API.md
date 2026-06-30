# Flashdrive API

The Flashdrive component handles USB interfaces, world/inventory flash-drive conversion, physical attachment to laptops, and virtual filesystem mounting under `/mnt/<interface>`.

Most mission makers should use player ACE interactions. Use this API when writing scripted scenarios, custom interactions, or integrations that need to attach, mount, unmount, or inspect flash drives.

## Concepts

| Concept | Meaning |
| --- | --- |
| USB interface | Named laptop connection point such as `usb0` or `usb1`. |
| Occupied interface | A flash drive object is physically attached to that port. |
| Mounted interface | The flash drive filesystem is visible under `/mnt/<interface>`. |
| Flash drive item | Inventory item class that can become a world object. |
| Flash drive object | World object storing `AE3_filesystem` and parent/interface metadata. |

## Mounting

### `AE3_flashdrive_fnc_mount`

Mounts a flash drive attached to a USB interface.

```sqf
[_computer, _interface, _username] call AE3_flashdrive_fnc_mount;
```

Arguments:

| Index | Type | Meaning |
| --- | --- | --- |
| `0` | Object | Computer/laptop with USB interfaces. |
| `1` | String | Interface name, for example `"usb0"`. |
| `2` | String | ArmaOS username that receives ownership/access on the mount point. |

Example:

```sqf
[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;
```

Behavior:

- Creates or reuses `/mnt/<interface>`.
- Pulls the flash drive filesystem from the server if needed.
- Lazily creates an empty filesystem for newly spawned/arsenal drives.
- Mounts the drive filesystem into the laptop filesystem.
- Updates mounted-interface state.
- Emits a desktop volume-change event so open file views can refresh.

Expected failures:

| Failure | Meaning |
| --- | --- |
| Interface does not exist | The laptop has no matching USB interface. |
| Interface empty | Nothing is attached to that USB port. |

### `AE3_flashdrive_fnc_unmount`

Unmounts a flash drive and saves the mounted filesystem back to the flash drive object.

```sqf
[_computer, _interface] call AE3_flashdrive_fnc_unmount;
```

Example:

```sqf
[_laptop, "usb0"] call AE3_flashdrive_fnc_unmount;
```

Unmount before removing a drive if you are bypassing normal player interactions. This preserves changes made while mounted.

## Physical Connection

### `AE3_flashdrive_fnc_connectFlashDrive`

Physically connects an inventory flash drive item to a laptop USB interface.

```sqf
[_computer, _player, _flashDriveClass, _USBInterface] call AE3_flashdrive_fnc_connectFlashDrive;
```

Arguments:

| Index | Type | Meaning |
| --- | --- | --- |
| `0` | Object | Laptop/computer. |
| `1` | Object | Player performing the action. |
| `2` | String | Flash drive item class name. |
| `3` | Array | USB interface config `[index, name, relPos, rotYaw, rotPitch, rotRoll]`. |

Example:

```sqf
private _interfaces = _laptop getVariable ["AE3_USB_Interfaces", createHashMap];
private _usb0 = _interfaces get "usb0";

[_laptop, player, "Item_FlashDisk_AE3_ID_1", _usb0] call AE3_flashdrive_fnc_connectFlashDrive;
```

The function converts the inventory item to a world object, attaches it to the laptop, records the occupied interface, and auto-mounts the drive as root on the server.

### `AE3_flashdrive_fnc_disconnectFlashDrive`

Physically disconnects a flash drive from a USB interface.

```sqf
[_computer, _player, _USBInterface] call AE3_flashdrive_fnc_disconnectFlashDrive;
```

Example:

```sqf
private _interfaces = _laptop getVariable ["AE3_USB_Interfaces", createHashMap];
[_laptop, player, _interfaces get "usb0"] call AE3_flashdrive_fnc_disconnectFlashDrive;
```

If the drive is mounted, the function unmounts it before converting the world object back to an inventory item.

## Inspecting Interfaces

### `AE3_flashdrive_fnc_lsInterfaces`

Returns a terminal-formatted list of USB interfaces and their status.

```sqf
private _lines = [_laptop] call AE3_flashdrive_fnc_lsInterfaces;
```

The function is marked internal in the source, but it is useful when building diagnostics or custom terminal commands. For player use, the built-in `lsusb` command already exposes this.

## Complete Scripted USB Example

```sqf
private _interfaces = _laptop getVariable ["AE3_USB_Interfaces", createHashMap];
private _usb0 = _interfaces get "usb0";

[_laptop, player, "Item_FlashDisk_AE3_ID_1", _usb0] call AE3_flashdrive_fnc_connectFlashDrive;
[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;

private _fs = _laptop getVariable "AE3_filesystem";
private _content = [[], _fs, "/mnt/usb0/brief.txt", "admin", 0] call AE3_filesystem_fnc_getFile;

[_laptop, "usb0"] call AE3_flashdrive_fnc_unmount;
[_laptop, player, _usb0] call AE3_flashdrive_fnc_disconnectFlashDrive;
```

## Common Failure Points

| Symptom | Check |
| --- | --- |
| Mount throws interface error | The laptop class may not define that USB port. Inspect `AE3_USB_Interfaces`. |
| Mount throws empty error | A drive must be physically connected before mounting. |
| Files disappear after removal | The drive was removed without unmounting, or custom code bypassed `disconnectFlashDrive`. |
| Desktop Files app does not refresh | Emit `["ae3_desktop_volChanged", []] call CBA_fnc_globalEvent;` after custom volume changes. |
| Inventory item does not convert | Confirm the class name is a valid AE3 flash drive item. |

## Related Pages

- [Filesystem API](Filesystem-API.md)
- [Terminal Commands](Terminal-Commands.md)
- [Flash Drives System](../Systems/Flash-Drives.md)

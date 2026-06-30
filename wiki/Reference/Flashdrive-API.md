# Flashdrive API

## Public Calls

| Function | Purpose |
| --- | --- |
| `AE3_flashdrive_fnc_item2obj` | Convert a flash drive inventory item to a world object. |
| `AE3_flashdrive_fnc_obj2item` | Convert a flash drive object to an inventory item. |
| `AE3_flashdrive_fnc_connectFlashDrive` | Attach a flash drive item to a laptop USB interface. |
| `AE3_flashdrive_fnc_disconnectFlashDrive` | Detach a flash drive from a laptop USB interface. |
| `AE3_flashdrive_fnc_mount` | Mount a connected drive into `/mnt/<interface>`. |
| `AE3_flashdrive_fnc_unmount` | Unmount and save drive filesystem state. |

## Examples

```sqf
private _drive = [player, "Item_FlashDisk_AE3_ID_1", getPos player] call AE3_flashdrive_fnc_item2obj;
[_drive, player] call AE3_flashdrive_fnc_obj2item;

[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;
[_laptop, "usb0"] call AE3_flashdrive_fnc_unmount;
```

USB interface arrays use `[index, name, relPos, rotYaw, rotPitch, rotRoll]`.

# Flash Drives

AE3 flash drives can exist as inventory items or world objects. When connected to a laptop USB interface, their filesystem can be mounted into the laptop filesystem.

## Terminal Flow

```text
lsusb
mount usb0
ls /mnt/usb0
cat /mnt/usb0/orders.txt
umount usb0
```

## Script API

```sqf
private _obj = [player, "Item_FlashDisk_AE3_ID_1", getPos player] call AE3_flashdrive_fnc_item2obj;
[_obj, player] call AE3_flashdrive_fnc_obj2item;

[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;
[_laptop, "usb0"] call AE3_flashdrive_fnc_unmount;
```

## GUI Relationship

Mounted flash drive files appear under `/mnt/<interface>` and can be browsed from the desktop Files app or the terminal.

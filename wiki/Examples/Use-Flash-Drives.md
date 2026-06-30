# Use Flash Drives

## Player Terminal Flow

```text
lsusb
mount usb0
ls /mnt/usb0
cat /mnt/usb0/orders.txt
umount usb0
```

## Scripted Mount

```sqf
[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;
```

## Inventory/Object Conversion

```sqf
private _obj = [player, "Item_FlashDisk_AE3_ID_1", getPos player] call AE3_flashdrive_fnc_item2obj;
[_obj, player] call AE3_flashdrive_fnc_obj2item;
```

Mounted files appear in the GUI Files app under `/mnt/usb0`.

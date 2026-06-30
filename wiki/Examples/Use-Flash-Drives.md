# Use Flash Drives

This recipe adds portable storage gameplay with AE3 flash drives. It includes Eden Editor, Zeus, and API workflows.

Flash drives are useful for courier objectives, evidence transfer, air-gapped intel, and situations where players need to move data between laptops.

## Player-Facing Flow

Players normally:

1. Find or receive a flash drive.
2. Connect it to a laptop through ACE interaction.
3. Open the GUI Files app or use terminal USB commands.
4. Read/copy the content.
5. Unmount/disconnect the drive if the mission expects safe removal.

Terminal flow:

```text
lsusb
mount usb0
ls /mnt/usb0
cat /mnt/usb0/brief.txt
umount usb0
```

## Eden Editor Workflow

Use this before mission start.

1. Place or provide an AE3 flash drive item/object depending on how the mission gives it to players.
2. Place an AE3 laptop with CLI or Both mode if players must use terminal USB commands.
3. If the GUI Files app is enough, GUI or Both mode can work.
4. Add files to the flash drive if your scenario uses preconfigured drive content.
5. Place the laptop where players can reach it.
6. Ensure the laptop has power.
7. Add a clue telling players the drive belongs in that laptop if the connection is not obvious.

If your Eden workflow cannot directly pre-seed the drive content, use the API workflow below during mission init.

## Zeus Workflow

Use this during live play.

1. Give or spawn a flash drive for players.
2. Direct players to a compatible AE3 laptop.
3. If a drive/laptop interaction breaks, check that the drive is attached to a USB interface and mounted.
4. Use Zeus file tools on the laptop if you need to add a fallback clue.
5. If players forget to unmount and content does not persist as expected, use Zeus/API repair only when it is fair to the mission.

Live-use examples:

- Zeus gives players a flash drive after they search a body.
- Zeus spawns a replacement drive if a physics issue loses the original.
- Zeus adds a fallback file to the laptop when players cannot operate terminal USB commands.

## API Workflow

Mounting and physical connection are usually player actions. Use API when scripting a scenario or debugging.

### Connect a Drive Item to a Laptop

```sqf
private _interfaces = _laptop getVariable ["AE3_USB_Interfaces", createHashMap];
private _usb0 = _interfaces get "usb0";

[_laptop, player, "Item_FlashDisk_AE3_ID_1", _usb0] call AE3_flashdrive_fnc_connectFlashDrive;
```

### Mount and Read

```sqf
[_laptop, "usb0", "admin"] call AE3_flashdrive_fnc_mount;

private _fs = _laptop getVariable "AE3_filesystem";
private _content = [[], _fs, "/mnt/usb0/brief.txt", "admin", 0] call AE3_filesystem_fnc_getFile;
systemChat _content;
```

### Unmount and Disconnect

```sqf
[_laptop, "usb0"] call AE3_flashdrive_fnc_unmount;

private _interfaces = _laptop getVariable ["AE3_USB_Interfaces", createHashMap];
[_laptop, player, _interfaces get "usb0"] call AE3_flashdrive_fnc_disconnectFlashDrive;
```

### Pre-Seed a Flash Drive Object

If you have a flash drive object in a variable `_drive`, you can seed its filesystem on the server:

```sqf
if (isServer) then {
    private _driveFs = [createHashMap, "root", [[true, true, true], [true, true, true]]];
    [[], _driveFs, "/brief.txt", "The relay code is 52.7.", "root", "root"] call AE3_filesystem_fnc_ensureFile;
    _drive setVariable ["AE3_filesystem", _driveFs, 2];
};
```

## Testing

1. Confirm the player can pick up or interact with the drive.
2. Confirm the laptop exposes USB interactions.
3. Test both GUI Files app and terminal flow if both are intended.
4. Confirm content persists after unmount/disconnect.
5. Test on dedicated server if flash drive content matters to mission completion.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| `lsusb` shows no drive | Drive is not physically connected to a USB interface. |
| `mount usb0` fails | Wrong interface name, empty port, or missing drive object state. |
| Files missing after disconnect | Unmount before disconnecting or use the public disconnect function. |
| Players have GUI-only laptop but instructions use terminal | Provide GUI file browsing instructions or set mode to Both. |
| Drive content differs per client | Ensure drive filesystem is stored/published on the server. |

## Related Pages

- [Flash Drives](../Systems/Flash-Drives.md)
- [Flashdrive API](../Reference/Flashdrive-API.md)
- [Filesystem API](../Reference/Filesystem-API.md)

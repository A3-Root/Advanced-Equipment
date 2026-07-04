# Flash Drives

Flash drives are portable storage. They can be carried by players, connected to laptop USB ports, mounted, read, unmounted, and disconnected. Use them whenever intel should be separable from the laptop it was found on.

## Player Flow

1. Find or receive a flash drive (an inventory item, e.g. `Item_FlashDisk_AE3_ID_1`).
2. Connect it to a laptop's USB port through ACE interaction ("Connect Flash Drive").
3. Use terminal USB commands, or the GUI Files app's volume list, to detect and mount it.
4. Open the mounted files through terminal or GUI Files app.
5. Unmount the drive when finished.
6. Disconnect it if the mission requires moving it elsewhere.

Terminal sequence a player actually types:

```text
lsusb
mount usb0
ls /mnt/usb0
cat /mnt/usb0/brief.txt
umount usb0
```

`lsusb` lists interfaces and shows which ones have a drive attached. `mount <interface>` (also usable from the GUI volume panel) makes the drive's files visible at `/mnt/<interface>`; `umount <interface>` saves changes back to the drive object before it is removed.

## Mission-Maker Setup

Use flash drives when:

- A clue must be physically transported between laptops.
- Players must choose which laptop to inspect it on.
- A password or key file should be separated from the main laptop.
- The mission wants evidence transfer or courier gameplay.

No-code setup in 3DEN:

1. Place a laptop with at least one USB interface (standard AE3 laptop variants already have them).
2. Place a flash drive item in a player's inventory, a crate, or on a body.
3. Add files/folders to the flash drive's own filesystem the same way you would a laptop — flash drives carry their own independent `AE3_filesystem`, not a copy of the laptop's.
4. Preview and connect the drive to a laptop as a player to confirm mount/read/unmount behavior.

## Mount Paths

Mounted drives appear under `/mnt/<interface>`, e.g. `/mnt/usb0`. The interface name comes from the laptop's USB port configuration, not the drive itself — the same physical drive mounts under whatever port it is plugged into.

## Common Problems

- **Drive connected but files are missing** — check whether it is mounted; connecting is not the same as mounting.
- **Cannot mount** — check the USB interface exists on that laptop class and that a drive is physically attached to it.
- **Cannot read files** — check file permissions or required credentials on the flash drive's own filesystem.
- **Drive disconnected too early** — unmounting saves state back to the drive; disconnecting without unmounting first can lose in-session changes. Reconnect and mount again if needed.
- **Files app / Terminal disagree on contents** — both read the same mounted filesystem; if one is stale, the desktop volume-change event may not have fired (script-driven mounts should trigger it, see [Flashdrive API](../Reference/Flashdrive-API.md)).

## Related Pages

- [Flashdrive API](../Reference/Flashdrive-API.md) — scripted connect/mount/unmount/disconnect calls.
- [Terminal Commands](../Reference/Terminal-Commands.md) — `lsusb`, `mount`, `umount`, `chown`.
- [Use Flash Drives](../Examples/Use-Flash-Drives.md) — full walkthrough example.

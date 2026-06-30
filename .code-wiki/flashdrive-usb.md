---
topic: flashdrive-usb
status: verified
last-verified: 2026-06-30
confidence_score: 1.0
priority: support
tokens: ~610
code-paths:
  - addons/flashdrive/
  - addons/filesystem/functions/fnc_mount.sqf
  - addons/desktop/functions/fnc_volHandle.sqf
related-topics: [filesystem-model, armaos-terminal, desktop-gui-and-browser, interaction-equipment]
related-docs:
  - wiki/Systems/Flash-Drives.md
  - wiki/Reference/Flash-Drive-API.md
---

# Flash Drive USB

## overview

The flashdrive component provides inventory/world flash drives, USB interface initialization, connect/disconnect behavior, lazy filesystem initialization, and mounting into laptop filesystems.

## current behavior

- Laptops expose USB interfaces through `AE3_USB_Interfaces`, `AE3_USB_Interfaces_occupied`, and `AE3_USB_Interfaces_mounted`.
- Flash drives can exist as inventory items or world objects; conversion helpers preserve drive state through item/object transitions.
- `AE3_flashdrive_fnc_mount` creates `/mnt/<interface>`, mounts the flash drive filesystem there, changes ownership for the active user, and broadcasts volume refresh events.
- If a flash drive has no filesystem at mount time, an empty filesystem is created lazily on the authoritative server copy.
- Mount failures are caught, logged, and forwarded to any open desktop volume UI through `ae3_desktop_volError`.
- The terminal uses commands such as `lsusb`, `mount`, and `unmount`; the GUI uses volume commands through `fnc_volHandle`.

## decisions

- Mount points are named after USB interface IDs. Stable paths like `/mnt/usb0` make CLI and GUI behavior predictable.
- Drives initialize lazily when first mounted because drives obtained through Arsenal or runtime spawning may not have gone through normal init events.
- Mount operation reports errors through global desktop events, giving the GUI volume view asynchronous feedback after a server-side request.

## gotchas

- Mount/unmount paths must update both the filesystem mount and the `AE3_USB_Interfaces_mounted` state list.
- Dedicated-server timing can leave a drive object unknown to the mounting client/server path until synced.
- Flash drive filesystems are separate `AE3_filesystem` structures mounted into laptop filesystems, not copied into the laptop by default.

## re-verify when

- USB interface config, item/object conversion, mount/unmount functions, or desktop volume commands change.

## references

- `addons/flashdrive/functions/fnc_mount.sqf`
- `addons/flashdrive/functions/fnc_connectFlashDrive.sqf`
- `addons/flashdrive/functions/fnc_disconnectFlashDrive.sqf`
- `addons/flashdrive/functions/fnc_item2obj.sqf`
- `addons/flashdrive/functions/fnc_obj2item.sqf`


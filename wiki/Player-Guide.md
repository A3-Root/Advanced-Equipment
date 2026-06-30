# Player Guide

Advanced Equipment devices are used through ACE interactions.

## Laptops

Laptops may expose a terminal interface, a graphical desktop, or both.

- Terminal/TUI: type commands such as `help`, `ls`, `cat`, `ip`, `ping`, `ssh`, `msg`, `mount`, and `unlock`.
- Desktop/GUI: open apps such as Files, Browser, Mail, Chat, Calendar, Map, Music, Settings, Terminal, and SysInfo.

Some laptops require a username and password. Some laptops allow only certain sides or players to use GUI or TUI access.

## Power and Network

Devices may need power before they work. Generators, batteries, and solar panels can feed laptops, routers, and lights. Routers provide network access for ping, SSH, chat, and network-aware desktop apps.

## Flash Drives

Flash drives can be carried as inventory items, connected to laptop USB interfaces, mounted from the terminal, and browsed through the filesystem.

```text
lsusb
mount usb0
ls /mnt/usb0
cat /mnt/usb0/readme.txt
umount usb0
```

# Mission Maker Guide

Mission makers can configure AE3 devices through 3DEN attributes, editor connections, modules, and SQF.

## Design Choices

- Use GUI desktop when players should inspect mail, browser pages, files, media, maps, or app windows.
- Use TUI terminal when players should solve command-line tasks, SSH into another laptop, mount USB drives, inspect logs, unlock files, or run custom commands.
- Use both when the laptop should feel like a full computer.

## Server-Side Setup

Most state-changing setup should run on the server:

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "admin", "swordfish"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "HQ", "Route", "Bridge crossing at 0600.", "admin@lan"] call AE3_desktop_fnc_addEmail;
};
```

## Mission-Building Areas

- Laptop access: [Configure GUI vs TUI Access](Examples/Configure-GUI-vs-TUI-Access.md)
- Files: [Add Files and Folders](Examples/Add-Files-and-Folders.md)
- Browser: [Add Webpages and Browser History](Examples/Add-Webpages-and-Browser-History.md)
- Networking: [Build a Network](Examples/Build-a-Network.md)
- Power: [Configure Power](Examples/Configure-Power.md)

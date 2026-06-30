# Zeus API

Most Zeus functions are module callbacks or filesystem browser internals. They are compiled for UI and curator behavior, but mission scripts should usually use the public desktop, filesystem, network, and power APIs instead.

## Useful Curator-Facing Functions

| Function | Purpose |
| --- | --- |
| `AE3_main_fnc_zeus_turnOnDevice` | Zeus turn-on operation. |
| `AE3_main_fnc_zeus_turnOffDevice` | Zeus turn-off operation. |
| `AE3_main_fnc_zeus_standbyDevice` | Zeus standby operation. |
| `AE3_main_fnc_zeus_connectToRouter` | Zeus network connect operation. |
| `AE3_main_fnc_zeus_disconnectFromRouter` | Zeus network disconnect operation. |
| `AE3_main_fnc_zeus_openFilesystemBrowser` | Open Zeus filesystem browser. |
| `AE3_main_fnc_zeus_module_addUser` | Add user module callback. |
| `AE3_main_fnc_zeus_module_addFile` | Add file module callback. |
| `AE3_main_fnc_zeus_module_addDir` | Add directory module callback. |
| `AE3_main_fnc_zeus_module_addConnection` | Add connection module callback. |
| `AE3_desktop_fnc_zeus_module_addIntel` | Add desktop intel module callback. |
| `AE3_desktop_fnc_zeus_module_interfaceAccess` | Interface access module callback. |

For scripted mission setup, prefer calls such as `AE3_desktop_fnc_addEmail`, `AE3_desktop_fnc_registerWebpage`, `AE3_filesystem_fnc_createFile`, `AE3_network_fnc_createNetworkConnection`, and `AE3_power_fnc_createPowerConnection`.

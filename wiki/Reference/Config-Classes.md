# Config Classes

AE3 devices are configured through nested classes on `CfgVehicles` and through registries such as `CfgAE3Apps`, `CfgOsFunctions`, `CfgSecurityCommands`, and `CfgFilesystemObjects`.

## Device Classes

Common nested classes:

- `AE3_Device`: display name, init behavior, and device capabilities.
- `AE3_InternalDevice`: internal device such as a built-in battery.
- `AE3_PowerInterface`: power input/output interface.
- `AE3_Consumer`: power draw.
- `AE3_Battery`: capacity, charge, recharge behavior.
- `AE3_Generator`: generator output, fuel, sounds.
- `AE3_SolarGenerator`: solar output behavior.
- `AE3_Equipment`: ACE interactions, animations, carry/drag/cargo setup.
- `AE3_USB_Interface`: USB interface positions and names.

## Filesystem Objects

`CfgFilesystemObjects` seeds default directories and files. `AE3_FilesystemObject` entries define path, type, content, owner, and permissions.

## Desktop Apps

`CfgAE3Apps` registers GUI desktop apps. A class can set display name, entry function, icon, default size, desktop visibility, singleton behavior, and filesystem requirement.

## Terminal Commands

`CfgOsFunctions` registers TUI commands. `CfgSecurityCommands` registers optional security commands.

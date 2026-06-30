# Config Classes

This page documents the config surfaces addon developers are most likely to extend. It is not a full dump of every class in the mod; it focuses on usable integration points.

## Addon Component Layout

Each addon component typically has:

```text
addons/<component>/
  config.cpp
  script_component.hpp
  XEH_PREP.hpp
  XEH_preInit.sqf
  functions/fnc_*.sqf
  CfgVehicles.hpp
  stringtable.xml
```

Functions are compiled through `XEH_PREP.hpp` and PREP macros. Do not use `execVM` to call component files directly.

## Equipment Classes

AE3 equipment is usually defined through config blocks under a vehicle/object class.

Common blocks:

| Block | Purpose |
| --- | --- |
| `AE3_Equipment` | Interaction/display behavior for a physical object. |
| `AE3_Device` | Power/device behavior. |
| `AE3_InternalDevice` | Internal battery or internal component. |
| `AE3_USB_Interface` | USB port definitions for flash drives. |
| `AE3_Consumer` | Power draw settings inside `AE3_Device`. |
| `AE3_PowerInterface` | Provider/consumer connection metadata. |
| `AE3_Battery` | Battery capacity/recharge/initial level. |

Laptop classes use these blocks to combine interaction, power, filesystem initialization, network behavior, and USB interfaces.

## Laptop Attribute Example

Laptop variants inherit from Arma laptop classes and define AE3 behavior:

```cpp
class Land_Laptop_03_black_F_AE3: Land_Laptop_03_black_F
{
    ae3_item = "Item_Laptop_AE3";
    scopeCurator = 2;
    editorCategory = "AE3_Assets";

    class AE3_Equipment
    {
        displayName = "Laptop";
        init = "call AE3_interaction_fnc_initLaptop;";
        openAction = "call AE3_interaction_fnc_laptop_open;";
        closeAction = "call AE3_interaction_fnc_laptop_close;";
    };

    class AE3_Device
    {
        defaultPowerLevel = 0;
        init = "(_this + [configFile >> 'AE3_FilesystemObjects']) call AE3_armaos_fnc_device_initComplete;";
        turnOnAction = "call AE3_network_fnc_dhcp_onTurnOn; call AE3_armaos_fnc_computer_turnOn;";
        turnOffAction = "call AE3_armaos_fnc_computer_turnOff;";

        class AE3_Consumer
        {
            powerConsumption = 0.01/3600;
            standbyConsumption = 0.0001/3600;
        };
    };
};
```

When extending this, keep behavior in functions and call those functions from config strings. That keeps config readable and makes validation easier.

## USB Interface Config

USB ports are named child classes:

```cpp
class AE3_USB_Interface
{
    class USB0
    {
        rel_pos[] = {-0.19, 0.042, -0.145};
        rot_yaw = 90;
        rot_pitch = 0;
        rot_roll = 0;
    };
};
```

Runtime interface data is stored on the laptop in `AE3_USB_Interfaces`.

## Filesystem Objects

Default laptop filesystem content comes from config under `AE3_FilesystemObjects`. The ArmaOS device initialization reads that config and creates the virtual filesystem.

Use filesystem modules or script APIs for mission-specific content. Use config defaults for addon-wide baseline content that should exist on every laptop of a given type.

Filesystem object concepts:

| Item | Meaning |
| --- | --- |
| Directory | HashMap-backed object. |
| File | String/code/marker-backed object. |
| Owner | User name assigned to object. |
| Permissions | Owner/everyone read/write/execute tuple. |

See [Filesystem API](Filesystem-API.md) for runtime shape and direct manipulation.

## Terminal Command Config

Terminal commands are config classes based on `OsFunction`.

```cpp
class OsFunction
{
    path = "";
    description = "";
    man = "";
    code = "";
};
```

Base commands live under `CfgOsFunctions`, optional security commands under `CfgSecurityCommands`, and games under `CfgGames`.

Example:

```cpp
class CfgOsFunctions
{
    class relayStatus: OsFunction
    {
        path = "/bin/relay";
        description = "Shows relay status.";
        man = "relay: prints relay status.";
        code = "call myMod_fnc_os_relay";
        sshCompatible = 1;
    };
};
```

Avoid square brackets in config strings where the existing command config warns against them.

## Desktop App Config

Native GUI apps can be registered in config with `CfgAE3Apps`.

```cpp
class CfgAE3Apps
{
    class myMod_tools
    {
        displayName = "Tools";
        entry = "myMod_fnc_toolsApp";
        icon = "";
        defaultSize[] = {0.55, 0.5};
        showOnDesktop = 1;
        singleton = 1;
        requiresFilesystem = 1;
    };
};
```

Runtime alternative:

```sqf
["myMod_tools", "Tools", "myMod_fnc_toolsApp", [0.55, 0.5], true, true] call AE3_desktop_fnc_registerApp;
```

See [Desktop Apps](Desktop-Apps.md).

## Eden Modules

AE3 modules are normal `Module_F` classes. Current module classes include:

| Module class | Purpose |
| --- | --- |
| `AE3_AddUser` | Add laptop user. |
| `AE3_AddCalendarEvent` | Add calendar event. |
| `AE3_SaveLaptop` | Save a laptop state. |
| `AE3_RestoreLaptop` | Restore a saved laptop state. |
| `AE3_AddFile` | Add a file. |
| `AE3_AddDir` | Add a directory. |
| `AE3_AddEmail` | Add email intel. |
| `AE3_AddWebpage` | Add browser page. |
| `AE3_AddBrowserHistory` | Add browser history. |
| `AE3_AddMedia` | Add media marker. |
| `AE3_AddPasswordedFile` | Add locked file. |
| `AE3_AddConnection` | Zeus connection workflow. |
| `AE3_InterfaceAccess` | Zeus interface access workflow. |
| `AE3_CrashDevice` | Crash device workflow. |

Module config uses attributes such as `function`, `isGlobal`, `isTriggerActivated`, `isDisposable`, `curatorInfoType`, and `ModuleDescription`.

For no-code use, see [Eden Attributes](Eden-Attributes.md) and [Eden Editor Guide](../Eden-Editor-Guide.md).

## Eden Connection Classes

AE3 adds custom 3DEN connection types:

```cpp
class AE3_PowerConnection
{
    displayName = "AE3: connect device to power source";
    data = "AE3_PowerConnection";
    expression = "[_entity0, _entity1] call AE3_power_fnc_createPowerConnection;";
};

class AE3_NetworkConnection
{
    displayName = "AE3: connect device to network router";
    data = "AE3_NetworkConnection";
    expression = "[_entity0, _entity1] call AE3_network_fnc_createNetworkConnection;";
};
```

These execute on mission start and create the runtime links.

## CBA Settings

Several components expose CBA settings. Important ones include:

| Setting | Component | Meaning |
| --- | --- | --- |
| `AE3_Desktop_DefaultMode` | Desktop | Default laptop interface mode when Eden does not override it. |
| `AE3_Desktop_EnableDragDrop` | Desktop | Enables desktop drag/drop behavior. |
| `AE3_Desktop_EnableFileBrowsing` | Desktop | Enables GUI file browsing behavior. |
| `AE3_Desktop_DefaultTheme` | Desktop | Default GUI theme. |
| `AE3_Filesystem_SyncMode` | Filesystem | Filesystem sync behavior. |
| `AE3_Power_ChangeThreshold` | Power | Power update threshold. |
| `AE3_Power_EnableStateSync` | Power | Power state sync behavior. |
| `AE3_Power_UpdateInterval` | Power | Power update cadence. |

Prefer CBA settings for mission/server policy and object attributes for per-object behavior.

## Related Pages

- [Eden Attributes](Eden-Attributes.md)
- [Desktop Apps](Desktop-Apps.md)
- [Terminal Commands](Terminal-Commands.md)
- [Addon Components](../Developer/Addon-Components.md)

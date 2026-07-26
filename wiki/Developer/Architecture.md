# Architecture

Advanced Equipment is split into independent addon components under `addons/`. Each component owns one domain, compiles its own functions, and exposes public behavior through documented APIs, config classes, Eden/Zeus modules, ACE interactions, or CBA events.

The design goal is modular equipment systems that can be used by mission makers without scripting, while still giving addon developers script/config hooks for custom laptops, terminal commands, desktop apps, browser content, power devices, routers, and flash drives.

## Component Map

| Component | Responsibility |
| --- | --- |
| `main` | Shared helpers, remote variable helpers, debug helpers, Zeus helpers, 3DEN connection handlers. |
| `armaos` | Terminal/TUI, users, login, shell command execution, command links, encryption commands, games, laptop state capture/apply. |
| `desktop` | GUI desktop, native apps, web desktop bridge, browser, mail, chat, media, CCTV, calendar, interface mode/access. |
| `filesystem` | Virtual filesystem, permissions, path resolution, files, directories, symlinks, mounts. |
| `flashdrive` | USB interfaces, flash drive item/object conversion, mount/unmount behavior. |
| `interaction` | ACE interactions, open/close animations, lamps, desks, interaction availability state. |
| `network` | Routers, DHCP, IPs, static IPs, routing, external access policy, SSH/message network delivery. |
| `power` | Power state, generators, batteries, solar panels, power links, fuel/battery levels, crashes. |

## Runtime State

Most runtime state is stored directly on objects with `setVariable`.

Examples:

| Variable | Owner | Meaning |
| --- | --- | --- |
| `AE3_filesystem` | Laptop/flash drive | Virtual filesystem object. |
| `AE3_Userlist` | Laptop | Username/password map. |
| `AE3_Links` | Laptop | Command name to command file link map. |
| `AE3_interfaceMode` | Laptop | `"cli"`, `"gui"`, or `"both"`. |
| `AE3_cliAccessCondition` | Laptop | CLI access condition. |
| `AE3_guiAccessCondition` | Laptop | GUI access condition. |
| `AE3_power_powerState` | Power-capable object | Numeric power state. |
| `AE3_power_internal` | Laptop | Internal battery object. |
| `AE3_power_powerCableDevice` | Consumer | Current power provider. |
| `AE3_network_parent` | Network device | Parent router/uplink. |
| `AE3_network_ip` | Network device | Current IP as `[a,b,c,d]`. |
| `AE3_USB_Interfaces` | Laptop | USB port config map. |
| `AE3_USB_Interfaces_occupied` | Laptop | Attached flash drive objects. |
| `AE3_USB_Interfaces_mounted` | Laptop | Mount status per port. |

Mission-wide registries use `missionNamespace` or server-owned object variables where that is cheaper and safer than duplicating state onto every client.

## Initialization Flow

Typical object initialization:

1. Arma creates object from config.
2. CBA Extended Event Handlers call component compile/init hooks.
3. Interaction config creates ACE actions.
4. Power config initializes device/provider/consumer state.
5. ArmaOS device initialization creates filesystem, users/links, and laptop state.
6. Network config initializes routers/devices and gateway/DHCP data.
7. Desktop post-init behavior provisions GUI state and app/media defaults.
8. Eden module and custom connection expressions apply mission-authored content/links.

Because these steps are event-driven, very early scripts must wait for the state they need:

```sqf
waitUntil { !isNil { _laptop getVariable "AE3_filesystem" } };
waitUntil { _laptop getVariable ["AE3_power_initDone", false] };
waitUntil { _router getVariable ["AE3_network_isRouter", false] };
```

## GUI and TUI Split

AE3 has two laptop interfaces:

| Interface | Component | Main user surface |
| --- | --- | --- |
| Terminal/TUI | `armaos` | Login prompt, shell commands, SSH, filesystem commands. |
| Desktop GUI | `desktop` | Windows, Files, Browser, Mail, Chat, Calendar, media viewers, settings. |

Both interfaces share the same laptop object, users, filesystem, power state, and network state. A mission can expose CLI only, GUI only, or both. Interface selection is controlled by the laptop attribute, CBA default, or `AE3_desktop_fnc_setInterfaceMode`.

When adding content, decide whether it should appear in:

| Content | Best backing system |
| --- | --- |
| A text file visible in both GUI and TUI | Filesystem file. |
| A terminal command | ArmaOS command link + command file. |
| A GUI desktop app | Desktop app registry/config. |
| A Browser page | Desktop webpage registry. |
| Email | Desktop mail helper. |
| Media asset | Desktop media marker. |
| Locked intel | Desktop locked-file helper. |

## Filesystem as Shared Contract

The filesystem is the main bridge between GUI and TUI. The Files app, Notepad-like behavior, media viewers, terminal commands such as `cat`, and custom command files all read from the same virtual filesystem.

This has two practical consequences:

1. Mission content should be created with stable paths.
2. Apps and commands should respect permissions and ownership unless they are deliberately acting as system/root behavior.

Use higher-level helpers where possible. They encode the marker formats expected by GUI apps:

```sqf
[_laptop, "informant@lan", "Subject", "Body"] call AE3_desktop_fnc_addEmail;
["media\photo.jpg", "image", "/home/admin/Desktop/photo.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;
```

Use direct filesystem calls when you need raw control:

```sqf
private _fs = _laptop getVariable "AE3_filesystem";
[[], _fs, "/home/admin/custom.txt", "Text", "root", "admin"] call AE3_filesystem_fnc_createFile;
_laptop setVariable ["AE3_filesystem", _fs, true];
```

## Multiplayer Ownership

The server is authoritative for durable mission state:

- Users.
- Filesystem content.
- Power states and provider/consumer links.
- Network links and router policy.
- Browser pages/history when targeted to laptops.
- Mail/media/locked-file content.

Clients are authoritative for local display state:

- Open desktop windows.
- Native app controls.
- Web browser control.
- Terminal display rendering.
- Local app registration.

When in doubt, make state changes on the server and UI changes on the client.

## Event and Refresh Pattern

Components notify open UI when backend state changes. Examples include:

| Event | Meaning |
| --- | --- |
| `ae3_desktop_volChanged` | Volumes/flash drive mounts changed. |
| `ae3_desktop_calChanged` | Calendar store changed. |
| `ae3_desktop_sysChanged` | System/power info changed. |
| `ae3_desktop_registerMedia` | Media registration event. |
| `ae3_network_imNotify` | Incoming message notification. |

If custom code changes state outside public APIs, you may need to emit the same refresh event. Prefer public APIs because they already do this.

## Extension Points

| Goal | Use |
| --- | --- |
| Add a terminal command to one laptop | `AE3_armaos_fnc_computer_addCustomCommand`. |
| Add an addon-wide terminal command | `CfgOsFunctions`. |
| Add a native GUI app | `CfgAE3Apps` or `AE3_desktop_fnc_registerApp`. |
| Add a web desktop extension | `AE3_desktop_fnc_registerExtApp` and `AE3_desktop_fnc_registerCmd`. |
| Add browser pages | `AE3_desktop_fnc_registerWebpage`. |
| Add media files | `AE3_desktop_fnc_registerMedia`. |
| Add custom equipment | Config `AE3_Equipment`, `AE3_Device`, and component-specific blocks. |
| Add Eden/Zeus workflows | Module classes calling public APIs. |

## Design Rules for New Code

- Keep domain logic in the owning component.
- Use public APIs between components where they exist.
- Do not make GUI code directly edit low-level network/power internals unless there is no public helper.
- Keep server state changes server-side.
- Keep client display code client-side.
- Publish changed object variables intentionally; do not broadcast huge state unless clients need it.
- Add Reference docs when you add a public function, config class, command, module, or app extension point.
- Add player-facing wiki updates when behavior affects Eden, Zeus, player interactions, GUI, or TUI workflows.

## Related Pages

- [Addon Components](Addon-Components.md)
- [Locality and Multiplayer](Locality-and-Multiplayer.md)
- [Debugging](Debugging.md)
- [API Overview](../Reference/API-Overview.md)

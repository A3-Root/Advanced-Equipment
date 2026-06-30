# Advanced Equipment Revamped (AE3)

<p align="center">
    <img src="AE3_Revamped_Logo.png" width="512">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0.1-blue" alt="version">
  <a href="https://github.com/y0014984/Advanced-Equipment/actions/workflows/auto-release.yml"><img src="https://github.com/y0014984/Advanced-Equipment/actions/workflows/auto-release.yml/badge.svg?branch=master" alt="build"></a>
  <a href="https://github.com/y0014984/Advanced-Equipment/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-APL--SA-blue.svg" alt="license"></a>
</p>


Advanced Equipment Revamped is an Arma 3 mod for game version 2.20+ that adds interactive, mission-ready equipment and a framework for building computer, power, network, and intel gameplay.

The mod centers on usable in-game laptops, routers, power generators, batteries, and lights. A laptop can expose a graphical desktop interface (GUI), a terminal command-line interface (TUI / CLI), or both. Mission makers can use these interfaces to build investigations, tasks, logistics puzzles, live Zeus intel drops, and persistent object-based systems.

## Requirements
Dependencies:
- [CBA_A3](https://github.com/CBATeam/CBA_A3)
- [ACE3](https://github.com/acemod/ACE3)

## What It Adds

### Interactive laptops

- GUI desktop with windows, apps, files, browser pages, mail, chat, calendar, map, CCTV, music, settings, and system info.
- TUI terminal with shell commands for files, users, networking, SSH, messaging, USB drives, encryption, cracking, and device control.
- Per-laptop interface mode: terminal only, desktop only, or both.
- Separate GUI and TUI access rules for sides, player UIDs, or custom script conditions.
- User accounts, passwords, home directories, command sets, and filesystem permissions.

### Mission intel tools

- Add files, folders, locked files, emails, browser webpages, browser history, media files, calendar entries, and CCTV cameras.
- Use the GUI Browser and Mail apps for readable intel.
- Use terminal logs and commands for investigation and puzzle flow.
- Add or modify content through 3DEN, Zeus, or SQF.

### Networking

- Routers with SSID, gateway, range, password, powered state, and external routing rules.
- DHCP, static IPs, ping, SSH, route resolution, and network messaging.
- Networked laptop workflows through both GUI apps and TUI commands.

### Power

- Generators, batteries, solar panels, and powered consumers.
- Fuel level, battery charge, solar output, standby, crash, and power connection behavior.
- Power-sensitive laptops, routers, lights, and other equipment.

### Flash drives and filesystem

- Flash drives that move between inventory and world objects.
- USB interfaces, mount/unmount behavior, and persistent virtual filesystems.
- Shared filesystem behavior between GUI Files app and terminal commands.

### Zeus and 3DEN support

- Modules for users, files, directories, connections, browser pages, browser history, email, media, locked files, calendar entries, interface access, and device operations.
- Zeus live-operation tools for adding intel, editing laptop files, connecting devices, and controlling power/network state during play.
- 3DEN attributes for laptop interfaces, router configuration, power levels, and mission setup.

## Documentation

The full documentation is in [wiki](wiki/Home.md).

Useful entry points:

- [Getting Started](wiki/Getting-Started.md)
- [Player Guide](wiki/Player-Guide.md)
- [Mission Maker Guide](wiki/Mission-Maker-Guide.md)
- [Zeus Guide](wiki/Zeus-Guide.md)
- [Desktop GUI](wiki/Systems/Desktop-GUI.md)
- [Terminal TUI](wiki/Systems/Terminal-TUI.md)
- [Browser and Webpages](wiki/Systems/Browser-and-Webpages.md)
- [API Overview](wiki/Reference/API-Overview.md)

## Links

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2888888564)
- [Discord](https://discord.gg/qQXg8tB7gr)

## License

Licensed under the Arma Public License - Share Alike. See [LICENSE](LICENSE) for the full license text.

Summary: you may share and adapt the material for non-commercial Arma use, with attribution, under the same license.

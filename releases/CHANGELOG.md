# Changelog

## Major Update 2 (v2.0.0.0)

### Added
- A new `desktop` addon that gives laptops a windowed graphical operating system alongside the existing terminal.
- Built-in desktop apps for Terminal, Files, Settings, Notepad, Mail, Chat, Browser, Calendar, Map, CCTV, Music, and System Information.
- A desktop window manager with focus, minimize, close, taskbar, per-app singleton handling, and configurable window sizes.
- Dark, Light, and Olive desktop themes, together with desktop wallpapers and system artwork.
- Native SQF desktop-app registration through `CfgAE3Apps` and runtime registration, plus web/JavaScript desktop extension and command/reply APIs.
- GUI workflows for mission intel: emails, chat messages, browser history, webpages, calendar events, media, maps, CCTV feeds, locked files, and filesystem browsing.
- Desktop launcher files seeded in the virtual filesystem, allowing missions to control which applications appear in a user's Desktop folder.
- Per-laptop interface modes for terminal-only, desktop-only, or combined access, with independent GUI/TUI restrictions for sides, player UIDs, and custom conditions.
- Made the laptop and flash drive inventory items available through the Virtual Arsenal and ACE Arsenal, and exposed the flash-drive world object to the Virtual Arsenal and Zeus.
- New 3DEN attributes and Zeus modules for adding intel, websites, calendar entries, interface-access rules, and live device operations.
- Laptop save and restore modules, with save-slot dialogs.
- New desktop-focused Zeus tools for creating and editing laptop files, folders, browser content, users, connections, and device state during live operations.
- Expanded terminal commands and support functions for SSH, network messaging, IP information, grep, sudo, unlock, command tokenization, simulated file transfers, and SSH session lifecycle management.
- Filesystem helpers for permissions, symlinks, directory/file creation, search, existence checks, and desktop launcher seeding.
- Router and connection-management features including password prompts, static IP configuration, wireless scanning, subnet/address checks, router configuration UI, and network-device validation.
- Calendar-event helpers, inventory-prop spawning/removal, device-initialization checks, and laptop state capture/application support.
- New sample browser sites and galleries, desktop artwork, image-to-base64 conversion tools, GitHub issue templates, a pull-request template, and expanded player, mission-maker, developer, API, and system documentation.

### Removed
- Deprecated terminal encryption/cracking commands and their supporting functions: `crack` and `crypto`.
- Legacy security-command and game modules, including their old Zeus-module variants.
- The former `ipconfig` and terminal `chat` command implementations, replaced by the newer IP and messaging workflow.
- Generator-running and battery-level helper functions that are no longer part of the updated power implementation.
- Archived design files, source artwork, source fonts, sound archives, and other development assets from the distributed project tree.
- Superseded top-level wiki pages for architecture, API reference, configuration, terminal guidance, security commands, encryption examples, and OS command customization; their material is now organized into the new documentation hierarchy.

### Changed
- Reworked the laptop lifecycle: deployment, pickup, inventory conversion, naming, storage, power-on/off/standby behavior, and state synchronization.
- Rebuilt terminal input and display handling, including keyboard layouts, history, autocomplete, mouse-wheel input, key events, render buffers, prompt handling, and battery/output updates.
- Updated the ArmaOS shell, command parsing, user/session handling, virtual filesystem integration, and terminal UI to support the expanded command set and GUI/TUI coexistence.
- Expanded integration across the ArmaOS, filesystem, networking, power, flash-drive, interaction, and main addons so devices, filesystems, power states, and network state are consistently available to desktop and terminal workflows.
- Updated ACE interactions, Zeus and 3DEN configuration, event handlers, string tables, vehicle definitions, editor categories, and public APIs across the mod.
- Added a dedicated-server requirement for Desktop mode: server administrators must allow `css`, `js`, and `md` in `allowedLoadFileExtensions[]` and `allowedHTMLLoadExtensions[]`; `b64` and `svg` must also be allowed when loading desktop images or alternate wallpapers.
- Documented the complete server extension allow-lists required by the GUI/Desktop browser, including HTML, text, CSS, JavaScript, Markdown, base64, and SVG content.
- Improved flash-drive and filesystem behavior, including mounting, unmounting, file movement, ownership, directory navigation, and permission checks.
- Updated power-device behavior for consumers, batteries, generators, solar panels, standby/crash states, fuel and charge tracking, and power connections.
- Reorganized and substantially expanded the README, Steam Workshop page, and wiki for v2 installation, server extension allow-lists, feature coverage, mission setup, developer extension points, testing, and contribution guidance.
- Added repository contribution workflow support and updated release/build metadata and automation for v2.0.0.0.

## Update 1 (v1.0.0.1)

### Added
- N/A

### Removed
- N/A

### Changed
- Fixed 'Add Security Commands' module breaking unix commands.

## Initial Public Release (v1.0.0.0)

### Added
- 16 New Themes + 4 Original Themes (20 in Total)
- Ability to carry laptops to inventory (with an experimental system implemented as well for future testing)
- Zeus File Browser
- Linear / Sorted Single ACE Interaction
- New Bootup Message
- More keyboard layout
- Autocompletion for files and commands inside the terminal
- Customizable settings for almost everything
- More localization checkes
- More stringtable localization
- New Battery status
- New Public API for custom development 

### Removed
- N/A

### Changed
- Refactored the code to meet new HEMTT standards
- Fix serialization warnings for performance
- Most API calls to be standardized

## Archive

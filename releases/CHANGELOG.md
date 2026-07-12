# Changelog

## Major Update 2 (v1.5.0.6)

### Added
- **Desktop GUI** environment as a full alternative to the terminal, with CLI <-> desktop switching (`sys_switch_cli` / `desktop` command)
- **Web Browser** app: multi-tab browsing with tab restore, mission-defined web roots + custom domains (`registerSite`), a RootNet home page, in-site relative links, and back/history navigation
- **Image Viewer**: native image rendering plus base64 image support (paste-and-render "Decode B64", base64 field on Add Media)
- Per-user desktop **wallpapers** with a picker
- Audio **seek bar** for media playback (video seeking not supported)
- **Mail** app with sender/recipient addressing tied to laptops
- New Zeus/3DEN modules: **Add Website**, **Save/Restore Laptop**, **Interface Access**, **Add Calendar Event**, and per-type **Add Intel** modules
- Executable files get a green tint in the file browser and can be run directly (`fs_list` exec flag, `sys_run_file`)
- `CfgEditorSubcategories` (8 subcategories) organizing AE3 objects in the 3DEN/Zeus editor tree
- Flash Drive in the Virtual Arsenal / ACE Arsenal
- AE3 Laptops in the Virtual Arsenal / ACE Arsenal
- WiFi Network with static IP, DHCP, SSH. It respects subnet boundaries when a device switches networks, falling back to DHCP if its saved static doesn't fit
- Optional **ZEN (Zeus Enhanced) Dynamic Dialog** support across Zeus modules, with non-ZEN fallback dialogs so Add Website / Save-Restore Laptop still work on dedicated servers without ZEN installed
- Maintainer-facing code wiki (`.code-wiki/`) and a graphify dependency graph for contributors
- Use laptop while inside a vehicle or stationary as long as its in the inventory

### Removed
- Zeus **Add Games** and **Add Security Commands** modules (the underlying terminal commands are still available, but they can no longer be added to a mission via a Zeus module)
- Terminal `chat` and `ipconfig` commands, non-functional/unused since v1.0.0.1
- `Crypto` and `Crack` apps (they are now in the `Root_Cyberwarfare` tools)

### Fixed
- Numerous runtime errors across ArmaOS, Network, and Desktop components found during QA passes
- Device power-on race condition
- Text cutoff in various menus
- SSH networking and time sync issues
- Various stringtable/localization typos

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

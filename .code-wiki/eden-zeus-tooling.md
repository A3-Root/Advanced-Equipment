---
topic: eden-zeus-tooling
status: verified
last-verified: 2026-06-30
confidence_score: 1.0
priority: core
rank: 2
tokens: ~810
code-paths:
  - addons/main/Cfg3DEN.hpp
  - addons/main/CfgUserInterfaceZeus.hpp
  - addons/main/functions/fnc_zeus_*.sqf
  - addons/main/CfgVehicles.hpp
  - addons/armaos/CfgVehicles.hpp
  - addons/filesystem/CfgVehicles.hpp
  - addons/network/CfgVehicles.hpp
  - addons/power/CfgVehicles.hpp
  - addons/*/functions/fnc_module_*.sqf
related-topics: [filesystem-model, network-routing-and-ssh, power-model, desktop-gui-and-browser, desktop-intel-and-communications]
related-docs:
  - wiki/Eden-Editor-Guide.md
  - wiki/Zeus-Guide.md
  - wiki/Examples/
---

# Eden Zeus Tooling

## overview

Editor tooling is split between 3DEN attributes/connections, Eden modules, Zeus modules/dialogs, and shared Zeus helper functions in the main component.

## current behavior

- 3DEN custom connections define power and network links. Power connections call `AE3_power_fnc_createPowerConnection`; network connections call `AE3_network_fnc_createNetworkConnection`.
- Laptop and router attributes live on their vehicle classes and set object variables for power level, interface mode, static IP, startup power state, router gateway, wireless range, password, and external access policy.
- Eden-visible modules exist in multiple components. Examples include adding users, files, directories, calendar events, emails, webpages, browser history, media, passworded files, and interface access/crash actions depending on scope.
- Zeus has custom dialogs and helper functions under `addons/main/functions/fnc_zeus_*.sqf` and `addons/main/CfgUserInterfaceZeus.hpp`.
- The Zeus Add Connection module validates exactly two synced objects and then creates either a power or network connection.
- Zeus filesystem browser operations are a larger sub-system: open, refresh, populate tree, create, save, delete, rename, move, apply changes, and close.
- Some module classes are intentionally Eden-only or Zeus-only through `scope` and `scopeCurator`.

## decisions

- Shared Zeus infrastructure lives in `addons/main` even when it manipulates filesystem, power, network, or ArmaOS state, because curator UI flows need one place for dialogs, validation, feedback, and object operation helpers.
- Eden connections are used for persistent graph-like power/network links, while Zeus uses modules and dialogs for runtime linking. Eden needs visible saved connection lines; Zeus needs a curated runtime workflow with validation and feedback.
- Content/intel modules are split by audience. Eden modules expose many detailed fields, while Zeus often uses consolidated runtime dialogs.
- Attribute expressions write directly to object variables; those variables are the contract consumed by init functions across components.

## gotchas

- Zeus module functions often run locally on the curator machine first, then call server-authoritative operations.
- Synchronized-object order matters for connection modules. Add Connection stores first synced object as `entity1` and second as `entity2`, with an optional switch flag.
- `scope` and `scopeCurator` must be checked separately when documenting modules. Some module classes use `scope = 2` with `scopeCurator = 0`, while `AE3_AddIntel` is curator-visible but hidden in Eden.
- Class validation for Zeus network connections is currently a fixed class-name list in `fnc_zeus_module_addConnection.sqf`.

## re-verify when

- Any module class, Zeus dialog, Cfg3DEN connection, object attribute, or Zeus filesystem browser function changes.

## references

- `addons/main/Cfg3DEN.hpp`
- `addons/main/CfgUserInterfaceZeus.hpp`
- `addons/main/functions/fnc_zeus_module_addConnection.sqf`
- `addons/main/functions/fnc_zeus_openFilesystemBrowser.sqf`
- `addons/armaos/CfgVehicles.hpp`
- `addons/desktop/CfgVehicles.hpp`
- `addons/filesystem/CfgVehicles.hpp`


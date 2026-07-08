---
topic: main-runtime-infrastructure
status: verified
last-verified: 2026-07-08
confidence_score: 1.0
priority: core
rank: 11
tokens: ~520
code-paths:
  - addons/main/
related-topics: [multiplayer-locality-and-sync, eden-zeus-tooling, network-routing-and-ssh, interaction-equipment, power-model, filesystem-model]
related-docs:
  - wiki/Developer/Locality-and-Multiplayer.md
---

# Main Runtime Infrastructure

## overview

The main component owns mission bootstrap wiring, capability flags, remote-variable transfer helpers, debug toggles, Zeus device-operation dispatch, and deletion cleanup shared across addons.

## current behavior

- `XEH_preInit.sqf` caches Zeus Enhanced availability in `AE3_main_hasZenDialog`, registers a deleted-object class handler that calls `AE3_main_fnc_terminateDevice`, and installs CBA settings for debug mode, network debug, and deployment type.
- `AE3_main_fnc_hasCapability` checks `AE3_cap_<name>` object variables and returns false for null entities.
- `AE3_main_fnc_getRemoteVar` only runs in multiplayer, respawns itself into scheduled context when needed, asks the remote owner to fill a local transfer slot, and waits for `_variable + "_trans"` to flip true.
- `AE3_main_fnc_sendVarToRemote` copies a variable value and its transfer flag back to the requested owner.
- `AE3_main_fnc_manageDebugMode` drives the local systemChat heartbeat and leaves the optional overlay path disabled through `_debugOverlayProductiveUse = false`.
- `AE3_main_fnc_manageNetworkDebug` only toggles the `AE3_NetworkDebugEnabled` mission variable; `AE3_main_fnc_netLog` reads that flag before writing to the RPT.
- `AE3_main_fnc_zeus_deviceOpServer` runs curator device operations on the server, ensures the target computer is initialized, and sends success or failure back to the curator owner through `ae3_main_zeusOpFeedback`.
- `AE3_main_fnc_zeus_deviceOpFeedback` renders curator hints for the specific operation and shows a filesystem-not-ready message when the server-side check fails.
- `AE3_main_fnc_terminateDevice` turns off powered devices, removes both power and network connections, clears the stable-laptop tracker entry, and removes tracked inventory props from units and vehicles.
- `AE3_main_fnc_getPlayersInRange` is a public helper that filters `BIS_fnc_listPlayers` by distance to an object; it is used for UI-on-texture update targeting.

## decisions

- The main component owns cross-cutting bootstrap and lifecycle hooks because several subsystems need one place for mission-wide settings, delete cleanup, and shared event registration.
- Capability checks are stored as public object variables instead of ad-hoc class probing so dependent code can test a device role with one stable helper.
- Zeus device mutations are server-authoritative, with curator-only feedback returned after the operation, because filesystem and content edits need one trusted execution path.
- The remote-variable pair (`getRemoteVar`/`sendVarToRemote`) uses a transfer flag instead of a direct return value because the request crosses machine boundaries and may originate from a scheduled or event-handler context.
- Network debug logging is opt-in and call-site based, which keeps the RPT readable while still allowing network traffic to be traced when needed.

## gotchas

- `getRemoteVar` waits, so callers in unscheduled contexts must let it respawn or explicitly spawn it.
- `manageDebugMode` and the overlay branch are client-side only; dedicated or server contexts will not show the local debug chat loop.
- `AE3_main_fnc_netLog` only records traffic at sites that call it, so missing entries can mean the caller never instrumented the path.
- `AE3_main_fnc_waitForFilesystem` still exists as a deprecated compatibility wrapper, but internal Zeus flows now rely on `AE3_armaos_fnc_device_ensureInit` through the server event path.
- `terminateDevice` only clears the stable-laptop tracker when the object appears in that map, so any new tracker format must keep the same lookup shape.
- The optional overlay path is effectively dormant because `_debugOverlayProductiveUse` is hardcoded false.

## references

- `addons/main/XEH_preInit.sqf`
- `addons/main/functions/fnc_getRemoteVar.sqf`
- `addons/main/functions/fnc_sendVarToRemote.sqf`
- `addons/main/functions/fnc_hasCapability.sqf`
- `addons/main/functions/fnc_manageDebugMode.sqf`
- `addons/main/functions/fnc_manageNetworkDebug.sqf`
- `addons/main/functions/fnc_netLog.sqf`
- `addons/main/functions/fnc_zeus_deviceOpServer.sqf`
- `addons/main/functions/fnc_zeus_deviceOpFeedback.sqf`
- `addons/main/functions/fnc_terminateDevice.sqf`
- `addons/main/functions/fnc_getPlayersInRange.sqf`
- `addons/main/functions/fnc_waitForFilesystem.sqf`

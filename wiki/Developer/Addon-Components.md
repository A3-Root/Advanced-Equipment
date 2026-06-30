# Addon Components

This page explains how AE3 addon components are organized and how to add new functions, config, modules, or docs without breaking the component boundaries.

## Standard Component Structure

Most components follow this shape:

```text
addons/<component>/
  config.cpp
  script_component.hpp
  XEH_PREP.hpp
  XEH_preInit.sqf
  XEH_postInit.sqf        optional
  CfgVehicles.hpp         optional
  Cfg3DEN.hpp             optional
  CfgEventHandlers.hpp    optional
  stringtable.xml
  functions/
    fnc_someFunction.sqf
```

| File | Purpose |
| --- | --- |
| `config.cpp` | Includes component config and declares patch metadata. |
| `script_component.hpp` | Component macros and shared include setup. |
| `XEH_PREP.hpp` | PREP entries for compiled functions. |
| `XEH_preInit.sqf` | CBA settings, class event handlers, compile-time registration. |
| `XEH_postInit.sqf` | Runtime/client/server setup after preInit. |
| `CfgVehicles.hpp` | Object/module classes. |
| `Cfg3DEN.hpp` | Eden attributes/connections. |
| `stringtable.xml` | Localized user-visible strings. |
| `functions/fnc_*.sqf` | SQF functions compiled by PREP. |

## Adding a Function

1. Create `addons/<component>/functions/fnc_myFunction.sqf`.
2. Add `PREP(myFunction);` to that component's `XEH_PREP.hpp`.
3. Keep the function inside the component that owns the behavior.
4. Add an SQFdoc-style header for public or nontrivial functions.
5. Document public functions in the relevant `wiki/Reference` page.

Function skeleton:

```sqf
#include "..\script_component.hpp"
/*
 * Author: Your Name
 * Description: Does one specific component-owned task.
 *
 * Arguments:
 * 0: _target <OBJECT> - Target object
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [_target] call AE3_component_fnc_myFunction;
 *
 * Public: Yes
 */

params [["_target", objNull, [objNull]]];

if (isNull _target) exitWith { false };

true
```

## Public vs Internal Functions

Mark a function public only when external scripts/addons should call it. Public functions need stable argument order, stable return shape, clear locality behavior, and wiki docs.

Internal functions may still have headers, but their contracts can assume UI state, event context, or component internals.

Good public function candidates:

- Adds mission content.
- Changes equipment state.
- Registers an extension point.
- Reads useful state in a stable format.
- Wraps low-level state safely.

Poor public function candidates:

- Control event callbacks.
- Dialog button handlers.
- Partial helpers that assume a specific display exists.
- Recursive implementation helpers.
- Functions that expose mutable internals without validation.

## Component Boundaries

Use the owning component for each domain:

| Change | Component |
| --- | --- |
| Terminal command parsing/output/login | `armaos` |
| GUI windows/apps/browser/mail/media | `desktop` |
| Files/directories/permissions | `filesystem` |
| Router/IP/reachability | `network` |
| Fuel/battery/power links | `power` |
| USB attach/mount behavior | `flashdrive` |
| ACE action state/animations | `interaction` |
| Zeus shared helpers/debug/remote var helpers | `main` |

If a feature crosses components, put orchestration in the most user-facing component and delegate details through public APIs. For example, a Desktop app that changes router settings should live in `desktop` but call `AE3_network_fnc_applyRouterConfig`.

## Config Additions

When adding config:

- Put object/module classes in the component that owns them.
- Keep large config blocks in `Cfg*.hpp` files included by `config.cpp`.
- Use localized strings for player-visible names/tooltips.
- Put script behavior in functions and call those from config strings.
- Prefer existing categories and attribute patterns.

Module example:

```cpp
class My_Module: Module_F
{
    scope = 2;
    scopeCurator = 2;
    displayName = "AE3: My Module";
    category = "AE3_armaosModules";
    function = "my_component_fnc_module_myModule";
    isGlobal = 0;
    isTriggerActivated = 1;
    isDisposable = 1;
};
```

## CBA Settings

Use CBA settings for mission/server policy, not per-object mission content.

Good setting candidates:

- Default GUI/TUI mode.
- Feature enable/disable switch.
- Sync interval.
- Debug mode.

Poor setting candidates:

- One laptop's password.
- One router's gateway.
- One mission's intel page.
- One object's starting file content.

## Events

AE3 uses CBA events for cross-machine and UI refresh workflows. When adding a new event:

- Name it with the `ae3_<component>_<event>` pattern.
- Keep payloads small and documented.
- Decide whether it is local, target, server, or global.
- Avoid using global events for large filesystem data.

Example:

```sqf
["ae3_desktop_sysChanged", []] call CBA_fnc_globalEvent;
```

## Documentation Expectations

Update docs when adding or changing:

| Change | Docs |
| --- | --- |
| Public SQF function | Relevant `wiki/Reference/*-API.md`. |
| Terminal command | `wiki/Reference/Terminal-Commands.md` and terminal developer guide. |
| GUI app | `wiki/Reference/Desktop-Apps.md` and desktop developer guide. |
| Browser workflow | Browser Reference and Developer browser guide. |
| Eden attribute/module | `wiki/Reference/Eden-Attributes.md` and no-code guide if user-facing. |
| Config extension point | `wiki/Reference/Config-Classes.md`. |
| Multiplayer behavior | `wiki/Developer/Locality-and-Multiplayer.md`. |

## Validation

Required final validation for code changes:

```sh
hemtt check -p -Lc14 -e
```

For docs-only changes, still run Markdown/link checks when available. If a docs change references commands or function names, validate them with `rg` against the repo.

## Related Pages

- [Architecture](Architecture.md)
- [Debugging](Debugging.md)
- [Config Classes](../Reference/Config-Classes.md)

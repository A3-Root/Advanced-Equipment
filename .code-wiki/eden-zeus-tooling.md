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
  - addons/main/functions/fnc_zen_createDialog.sqf
  - addons/*/functions/fnc_zen_module_*.sqf
  - addons/main/functions/fnc_zeus_applyConnection.sqf
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
- Add Intel is split in Zeus into standalone per-type modules: `AE3_AddEmail`, `AE3_AddWebpage`, `AE3_AddBrowserHistory`, `AE3_AddMedia`, `AE3_AddPasswordedFile` are now `scopeCurator = 2` and share `curatorInfoType = AE3_UserInterface_Zeus_Module_AddIntel`. Each carries `ae3_intelType`; the shared dialog reads it (`configOf _module >> "ae3_intelType"`) to preset+lock the type picker (non-ZEN) or route straight to the matching ZEN step-2 form (or the legacy Browse dialog for media/lockedfile). The unified `AE3_AddIntel` is now `scopeCurator = 0` (hidden from Zeus) but kept so its shared dialog and 3DEN wiring stay defined. Eden/trigger placement is unchanged (per-type `Attributes` + `AE3_desktop_fnc_module_addIntel`).
- The Add User ZEN dialog pre-fills `admin` / `admin123` as default username/password (`fnc_zen_module_addUser`).
- ZEN Add Calendar Event has a Time (HH:MM) field, appended to the event tuple. ZEN Interface Access uses two `OWNERS` pickers (CLI access / GUI access) instead of per-player combos; empty picker = allow-all (`{true}`), otherwise a UID+side array passed to `setInterfaceAccess`. New `AE3: Add Website` module (Eden attrs Domain/SiteRoot; Zeus via ZEN `fnc_zen_module_addWebsite`) registers custom browser domains.
- Save/Restore Laptop target resolution: `fnc_module_saveLaptop`/`fnc_module_restoreLaptop` must resolve their laptop themselves. A curator dropping the module directly onto a laptop spawns it with an **empty** synced-object list, so both now use the crashDevice pattern - filter the synced units with `_isLaptop` (`isClass (configOf _x >> "AE3_USB_Interface")` or `AE3_cap_hasTerminal`) and fall back to `nearestObjects [_module, [], 3]` when empty - before the ZEN `remoteExec`/non-ZEN apply. Without this the save/restore loops iterated `[]` (captured/applied nothing) and login later failed with the hardcoded `"Unknown user"` (`fnc_authUser.sqf`). `fnc_zen_module_restoreLaptop` no longer fabricates a `slot1` when the save buffer is empty; it hints "no saved snapshots" and drops the module.
- 3DEN/Zeus asset tree: top-level `AE3_Assets` (`CfgEditorCategories`) plus a `CfgEditorSubcategories` block (both in `addons/main/CfgEditorCategories.hpp`) with 8 subcats (`AE3_Sub_Furniture/Storage/Lights/Routers/Power/Battery/Laptop/SolarPanel`). Each AE3 world object sets `editorCategory = "AE3_Assets"` + its `editorSubcategory`; variants inherit from their base. Both Eden and Zeus read these same two properties. Module (Logic) classes are untouched (they use `category`).
- Save/Restore Laptop clone: `applyState` applies the big nested `AE3_filesystem`/`AE3_filepointer` **server-local** (flag 2, like a normal laptop) and only broadcasts the small vars - broadcasting the CODE-bearing filesystem publicly stalled the client's `getRemoteVar` chain so the userlist never arrived ("Unknown user"/login timeout). It also re-broadcasts `AE3_Userlist` + fires `ae3_computer_userAdded`, re-binds networking with the restored parent/address, and `restoreLaptopApply` calls `device_ensureInit` on the fresh target first. Exclusion set is compared case-insensitively; session vars excluded so a clone starts signed out.
- Zeus curator Filesystem Browser (`idd 16993`): path field `1400` shortened so the pick-mode "Select Path" button `2900` is not covered; `onUnload` returns the path on OK (exit code 1) in pick mode, not just via the button; `refresh` resets the listbox selection (`lbSetCurSel -1`) so it no longer auto-picks the first file. Add Media's intel dialog reuses the shared `1714`/`1405` row as a "File Name with Extension" field (combined with the Browse-picked destination folder), overwriting a case-insensitive name match.
- Optional ZEN (Zeus Enhanced) compat: when the `zen_dialog` addon is loaded, the Zeus modules present ZEN's Dynamic Dialog (`zen_dialog_fnc_create`) instead of the built-in `CfgUserInterfaceZeus` dialogs. Detection is cached once in `addons/main/XEH_preInit.sqf` as `AE3_main_hasZenDialog` (`EGVAR(main,hasZenDialog)`); ZEN is never a required addon and is referenced only from guarded SQF (never config). All ZEN builders route through the guarded wrapper `AE3_main_fnc_zen_createDialog`.
  - Dialog modules (AddUser/AddCalendarEvent/AddFile/AddDir/AddConnection/AddIntel/InterfaceAccess): the legacy `curatorInfoType` handler still opens, but its `onLoad` bails when `hasZenDialog` - it captures the target laptop, sets `AE3_<component>_zenHandled` on the module (so the legacy `onUnload` skips its cleanup), `closeDisplay 2`, then opens the ZEN builder one frame later via `CBA_fnc_execNextFrame`. The ZEN `onConfirm`/`onCancel` funnel into the exact same apply layer (`intel_dispatch`, the `ae3_main_zeusDeviceOp` serverEvent, `setInterfaceMode`/`setInterfaceAccess`, and the extracted `AE3_main_fnc_zeus_applyConnection`) and own the module lifecycle.
  - AddIntel is a two-step ZEN dialog (type combo, then type-specific fields). Media and lockedfile keep the legacy dialog for its filesystem Browse picker: step 1 reopens `AE3_UserInterface_Zeus_Module_AddIntel` with `uiNamespace` override `AE3_desktop_intelZenOverride = [module, computer]` and clears `zenHandled` so the legacy handler runs normally.
  - AddFile has a "This is a Picture" checkbox + "Image type" combo (Eden attrs `AE3_Module_AddFile_IsPicture`/`_PictureType`; Zeus dialog idc `1309`/`1502`; ZEN two extra rows). When checked, `_content` is treated as raw base64 and stored by `device_addFile` as an inline image marker `AE3_MEDIA|image|b64|<mime>|<data>` (overrides code/encryption; empty encryption key no longer blocks it). Cap `AE3_MAX_PICTURE_B64` (2,097,152 chars) enforced server-side in `device_addFile` and pre-checked client-side (feedback `STR_AE3_Main_Zeus_PictureTooLarge`). MIME resolved from the combo or auto-detected from the base64 magic prefix. Only the web desktop's Image Viewer can render these (data URL); the native viewer declines them (`STR_AE3_Desktop_Files_PictureWebOnly`). `device_addFile` param order: `..., _overwrite, _isPicture, _pictureType`.
  - No-dialog modules (CrashDevice/SaveLaptop/RestoreLaptop) gain a curator prompt only under ZEN: the server module function `remoteExec`s a ZEN-prompt fn onto `owner _module`; the curator's `onConfirm` sends the decision back to the server (`remoteExec [..., 2]`) which runs the existing crash/capture/apply logic (Save/Restore extracted into `AE3_armaos_fnc_module_saveLaptopApply` / `_restoreLaptopApply`). Save/Restore let the curator name/pick a slot they previously could not set in Zeus. Restore builds a COMBO from the actual stored keys of `AE3_LAPTOP_SAVES` (a name-keyed HashMap, so multiple named saves coexist), sorted ascending; slot names are `trim`med on both save and restore so trailing spaces cannot desync the key. The hardcoded `slot1` fallback only applies to the non-ZEN Eden-attribute path.

## decisions

- Shared Zeus infrastructure lives in `addons/main` even when it manipulates filesystem, power, network, or ArmaOS state, because curator UI flows need one place for dialogs, validation, feedback, and object operation helpers.
- Eden connections are used for persistent graph-like power/network links, while Zeus uses modules and dialogs for runtime linking. Eden needs visible saved connection lines; Zeus needs a curated runtime workflow with validation and feedback.
- Content/intel modules are split by audience. Eden modules expose many detailed fields, while Zeus often uses consolidated runtime dialogs.
- Attribute expressions write directly to object variables; those variables are the contract consumed by init functions across components.

## gotchas

- Zeus module functions often run locally on the curator machine first, then call server-authoritative operations.
- Synchronized-object order matters for connection modules. Add Connection stores first synced object as `entity1` and second as `entity2`, with an optional switch flag.
- `scope` and `scopeCurator` must be checked separately when documenting modules. Some module classes use `scope = 2` with `scopeCurator = 0`, while `AE3_AddIntel` is curator-visible but hidden in Eden.
- Class validation for Zeus network connections is currently a fixed class-name list, now living in the shared `fnc_zeus_applyConnection.sqf` (extracted from `fnc_zeus_module_addConnection.sqf` so both the legacy dialog and the ZEN dialog reuse it).
- ZEN builders run on the curator's machine. For the dialog modules the module logic is curator-local (same as the legacy handlers, which `deleteVehicle` on the curator). For the no-dialog modules the effect stays server-authoritative and the module is deleted server-side via `remoteExec [..., 2]`. ZEN's `zen_dialog_fnc_create` no-ops on headless (`!hasInterface`), so `owner _module` must resolve to a real curator client.
- ZEN row labels use literal English strings (not stringtable keys) to avoid stringtable churn; titles reuse the existing `STR_AE3_*` module display-name keys (ZEN auto-localizes localized keys and uppercases titles).

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


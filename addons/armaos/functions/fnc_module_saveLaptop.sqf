#include "..\script_component.hpp"
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Eden/Zeus module function that snapshots every synced laptop's full state (filesystem,
 * users, calendar, mail, handles, network config, ...) into a named save slot held in the mission
 * buffer AE3_LAPTOP_SAVES. A Restore Laptop module placed on a fresh laptop later re-applies that
 * slot, letting mission makers swap out a laptop that went out of bounds or was disabled without
 * rebuilding its contents. Runs on the server for both editor and curator placement. The module is
 * deleted after processing.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module object
 * 1: _syncedUnits <ARRAY> - Synced laptop objects
 * 2: _activated <BOOL> - Module activation state
 *
 * Return Value:
 * <BOOL> - Activation handled
 *
 * Example:
 * [_module, [_laptop], true] call AE3_armaos_fnc_module_saveLaptop;
 *
 * Public: No
 */

params ["_module", "_syncedUnits", "_activated"];

if (!_activated) exitWith { true };
if (!isServer) exitWith {};

// When Zeus Enhanced is present, ask the placing curator for the save slot name through a ZEN dialog,
// then let its confirm callback drive the same server-side snapshot via AE3_armaos_fnc_module_saveLaptopApply.
if (EGVAR(main,hasZenDialog)) exitWith
{
    [netId _module, _syncedUnits apply { netId _x }] remoteExec [QFUNC(zen_module_saveLaptop), owner _module];
    true
};

private _slot = _module getVariable ["AE3_ModuleSaveSlot", ""];
if (_slot isEqualTo "") then { _slot = "slot1"; };

[_module, _syncedUnits, _slot] call FUNC(module_saveLaptopApply);

true

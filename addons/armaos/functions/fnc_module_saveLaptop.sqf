// File: fnc_module_saveLaptop.sqf
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

// Resolve the target laptops. A curator dropping this module directly onto a laptop spawns it at the
// laptop's position without a synchronization link, so the synced-object list is empty. Filter the
// synced objects to AE3 laptops and, when none are linked, fall back to the nearest laptop around the
// module so a placed-on-laptop module still finds its target.
private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
private _objs = _syncedUnits select { _x call _isLaptop };
if (_objs isEqualTo []) then
{
    private _near = (nearestObjects [_module, [], 3]) select { _x call _isLaptop };
    if (_near isNotEqualTo []) then { _objs = [_near select 0]; };
};

// Curator placement asks the placing curator for the save slot name through a dialog on their machine
// - the ZEN Dynamic Dialog when Zeus Enhanced is loaded, otherwise the built-in prompt. Both hand the
// chosen slot back to the server to drive the snapshot via AE3_armaos_fnc_module_saveLaptopApply.
if (_module getVariable ["BIS_fnc_moduleInit_isCuratorPlaced", false]) exitWith
{
    private _dialogFnc = [QFUNC(zeus_module_saveLaptop), QFUNC(zen_module_saveLaptop)] select (EGVAR(main,hasZenDialog));
    [netId _module, _objs apply { netId _x }] remoteExec [_dialogFnc, owner _module];
    true
};

// Eden / trigger placement reads the slot from the module attribute.
private _slot = _module getVariable ["AE3_ModuleSaveSlot", ""];
if (_slot isEqualTo "") then { _slot = "slot1"; };

[_module, _objs, _slot] call FUNC(module_saveLaptopApply);

true

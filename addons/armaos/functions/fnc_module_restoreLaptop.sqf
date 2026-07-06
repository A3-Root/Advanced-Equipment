#include "..\script_component.hpp"
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Eden/Zeus module function that overwrites every synced laptop with a state snapshot
 * previously captured by a Save Laptop module into the named slot (mission buffer AE3_LAPTOP_SAVES).
 * The target laptop receives the saved filesystem, users, calendar, mail, handles and network config,
 * then has its command links and network bindings rebuilt so it is immediately usable. Runs on the
 * server for both editor and curator placement. The module is deleted after processing.
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
 * [_module, [_laptop], true] call AE3_armaos_fnc_module_restoreLaptop;
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

// When Zeus Enhanced is present, let the placing curator pick the slot from a ZEN dialog listing the
// stored snapshots, then drive the same server-side restore via AE3_armaos_fnc_module_restoreLaptopApply.
if (EGVAR(main,hasZenDialog)) exitWith
{
    private _slots = keys (missionNamespace getVariable ["AE3_LAPTOP_SAVES", createHashMap]);
    [netId _module, _objs apply { netId _x }, _slots] remoteExec [QFUNC(zen_module_restoreLaptop), owner _module];
    true
};

private _slot = _module getVariable ["AE3_ModuleSaveSlot", ""];
if (_slot isEqualTo "") then { _slot = "slot1"; };

[_module, _objs, _slot] call FUNC(module_restoreLaptopApply);

true

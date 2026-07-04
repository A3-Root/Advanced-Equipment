#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced curator prompt for the Restore Laptop module. Runs on the placing curator's
 * machine (reached via remoteExec from the server module function). Lets the curator pick a stored save
 * slot from a ZEN Dynamic Dialog combo, then sends the choice back to the server to perform the restore.
 * On cancel the module is dropped server-side.
 *
 * Arguments:
 * 0: _moduleNetId <STRING> - netId of the module logic
 * 1: _syncedNetIds <ARRAY> - netIds of the synced laptops
 * 2: _slots <ARRAY> - Available save slot names
 *
 * Return Value:
 * None
 *
 * Example:
 * [_moduleNetId, _syncedNetIds, ["slot1"]] call AE3_armaos_fnc_zen_module_restoreLaptop;
 *
 * Public: No
 */

params ["_moduleNetId", "_syncedNetIds", ["_slots", []]];

// A combo needs at least one entry; fall back to the default slot when nothing has been saved yet.
if (_slots isEqualTo []) then { _slots = ["slot1"]; };

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_slot"];
    _args params ["_moduleNetId", "_syncedNetIds"];

    [_moduleNetId, _syncedNetIds, _slot] remoteExec [QFUNC(module_restoreLaptopApply), 2];
};

private _onCancel = {
    params ["_values", "_args"];
    (objectFromNetId (_args select 0)) remoteExec ["deleteVehicle", 2];
};

[
    "STR_AE3_ArmaOS_Config_RestoreLaptopDisplayName",
    [
        ["COMBO", "Save slot", [_slots, _slots, 0]]
    ],
    _onConfirm,
    _onCancel,
    [_moduleNetId, _syncedNetIds]
] call EFUNC(main,zen_createDialog);

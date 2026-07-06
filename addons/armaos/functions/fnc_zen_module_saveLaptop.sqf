#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced curator prompt for the Save Laptop module. Runs on the placing curator's
 * machine (reached via remoteExec from the server module function). Asks for the save slot name through a
 * ZEN Dynamic Dialog, then sends the choice back to the server to perform the snapshot. On cancel the
 * module is dropped server-side.
 *
 * Arguments:
 * 0: _moduleNetId <STRING> - netId of the module logic
 * 1: _syncedNetIds <ARRAY> - netIds of the synced laptops
 *
 * Return Value:
 * None
 *
 * Example:
 * [_moduleNetId, _syncedNetIds] call AE3_armaos_fnc_zen_module_saveLaptop;
 *
 * Public: No
 */

params ["_moduleNetId", "_syncedNetIds"];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_slot"];
    _args params ["_moduleNetId", "_syncedNetIds"];

    _slot = trim _slot;
    if (_slot isEqualTo "") then { _slot = "slot1"; };
    [_moduleNetId, _syncedNetIds, _slot] remoteExec [QFUNC(module_saveLaptopApply), 2];
};

private _onCancel = {
    params ["_values", "_args"];
    (objectFromNetId (_args select 0)) remoteExec ["deleteVehicle", 2];
};

[
    "STR_AE3_ArmaOS_Config_SaveLaptopDisplayName",
    [
        ["EDIT", "Save slot name", ["slot1"]]
    ],
    _onConfirm,
    _onCancel,
    [_moduleNetId, _syncedNetIds]
] call EFUNC(main,zen_createDialog);

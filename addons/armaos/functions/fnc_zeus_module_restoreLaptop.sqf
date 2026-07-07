#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Built-in curator prompt for the Restore Laptop module, used when Zeus Enhanced is not
 * loaded. Runs on the placing curator's machine (reached via remoteExec from the server module
 * function). Opens the built-in dialog and fills its combo with the server-provided save-slot list.
 * The dialog's onUnload sends the chosen slot back to the server through
 * AE3_armaos_fnc_module_restoreLaptopApply. With no stored snapshots the curator is told and the
 * module is dropped instead of presenting an empty picker.
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
 * [_moduleNetId, _syncedNetIds, ["slot1"]] call AE3_armaos_fnc_zeus_module_restoreLaptop;
 *
 * Public: No
 */

params ["_moduleNetId", "_syncedNetIds", ["_slots", []]];

// Present the stored slots in a stable alphabetical order so the picker reads predictably as the
// number of saves grows.
_slots sort true;

// With no stored snapshots there is nothing to restore. Tell the curator and drop the module instead
// of presenting an empty picker.
if (_slots isEqualTo []) exitWith
{
    [localize "STR_AE3_ArmaOS_Config_RestoreLaptopDisplayName", "No saved laptop snapshots - use Save Laptop first.", 5] call BIS_fnc_curatorHint;
    (objectFromNetId _moduleNetId) remoteExec ["deleteVehicle", 2];
};

uiNamespace setVariable ["AE3_armaos_restoreLaptopArgs", [_moduleNetId, _syncedNetIds]];

if (!createDialog "AE3_UserInterface_Zeus_Module_RestoreLaptop") exitWith
{
    (objectFromNetId _moduleNetId) remoteExec ["deleteVehicle", 2];
};

private _combo = (findDisplay 17131) displayCtrl 1500;
lbClear _combo;
{
    private _idx = _combo lbAdd _x;
    _combo lbSetData [_idx, _x];
} forEach _slots;
_combo lbSetCurSel 0;

// File: fnc_module_restoreLaptopApply.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side restore worker for the Restore Laptop module. Overwrites every synced laptop
 * with the state snapshot stored in the named slot of the mission buffer AE3_LAPTOP_SAVES, then deletes
 * the module. Shared by the standard module path (slot from the Eden attribute) and the Zeus Enhanced
 * dialog path (slot from the curator prompt). Accepts objects or netIds so it can be reached via
 * remoteExec from the curator's confirm callback.
 *
 * Arguments:
 * 0: _module <OBJECT|STRING> - The module logic (object or netId)
 * 1: _syncedUnits <ARRAY> - Synced laptop objects or netIds
 * 2: _slot <STRING> - Save slot name
 *
 * Return Value:
 * <BOOL> - Handled
 *
 * Example:
 * [_module, [_laptop], "slot1"] call AE3_armaos_fnc_module_restoreLaptopApply;
 *
 * Public: No
 */

params ["_module", "_syncedUnits", ["_slot", ""]];

if (!isServer) exitWith { false };

if (_module isEqualType "") then { _module = objectFromNetId _module; };
_syncedUnits = _syncedUnits apply { if (_x isEqualType "") then { objectFromNetId _x } else { _x } };
// Match the normalisation used when the slot was saved so the stored key resolves reliably.
_slot = trim _slot;
if (_slot isEqualTo "") then { _slot = "slot1"; };

[_module, _syncedUnits, _slot] spawn {
    params ["_module", "_syncedUnits", "_slot"];

    waitUntil { !isNil "BIS_fnc_init" };

    private _saves = missionNamespace getVariable ["AE3_LAPTOP_SAVES", createHashMap];
    private _state = _saves getOrDefault [_slot, createHashMap];

    // No snapshot stored for this slot - nothing to restore.
    if (count _state == 0) exitWith {
        diag_log text format ["[AE3 armaos] Restore Laptop: no saved snapshot for slot '%1'", _slot];
        deleteVehicle _module;
    };

    {
        private _computer = _x;
        if (!isNull _computer) then {
            // Force the fresh device to finish its own init (a just-spawned laptop may not have yet),
            // then apply once ready so the snapshot is not raced or lost to a pending init.
            [_computer] call AE3_armaos_fnc_device_ensureInit;
            waitUntil {
                sleep 0.1;
                _computer getVariable ["AE3_filesystemReady", false]
            };
            [_computer, _state] call AE3_armaos_fnc_laptop_applyState;
        };
    } forEach _syncedUnits;

    deleteVehicle _module;
};

true

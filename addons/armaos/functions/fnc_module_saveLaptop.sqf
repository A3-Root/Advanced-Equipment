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

private _slot = _module getVariable ["AE3_ModuleSaveSlot", ""];
if (_slot isEqualTo "") then { _slot = "slot1"; };

[_module, _syncedUnits, _slot] spawn {
    params ["_module", "_syncedUnits", "_slot"];

    waitUntil { !isNil "BIS_fnc_init" };

    private _saves = missionNamespace getVariable ["AE3_LAPTOP_SAVES", createHashMap];

    {
        private _computer = _x;
        if (!isNull _computer) then {
            // Snapshot only once the device has finished initializing, so its data is complete.
            waitUntil {
                sleep 0.1;
                _computer getVariable ["AE3_filesystemReady", false]
            };
            _saves set [_slot, [_computer] call AE3_armaos_fnc_laptop_captureState];
        };
    } forEach _syncedUnits;

    // Server-side buffer only - the snapshot holds HashMaps that must not be broadcast.
    missionNamespace setVariable ["AE3_LAPTOP_SAVES", _saves, false];

    deleteVehicle _module;
};

true

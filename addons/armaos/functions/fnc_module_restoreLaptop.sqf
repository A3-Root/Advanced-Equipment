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

private _slot = _module getVariable ["AE3_ModuleSaveSlot", ""];
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
            // Apply only once the fresh device has finished its own initialization.
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

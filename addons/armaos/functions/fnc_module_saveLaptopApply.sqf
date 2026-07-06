#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side snapshot worker for the Save Laptop module. Captures every synced laptop's
 * full state into the named slot of the mission buffer AE3_LAPTOP_SAVES, then deletes the module. Shared
 * by the standard module path (slot from the Eden attribute) and the Zeus Enhanced dialog path (slot from
 * the curator prompt). Accepts objects or netIds for the module and synced units so it can be reached via
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
 * [_module, [_laptop], "slot1"] call AE3_armaos_fnc_module_saveLaptopApply;
 *
 * Public: No
 */

params ["_module", "_syncedUnits", ["_slot", ""]];

if (!isServer) exitWith { false };

if (_module isEqualType "") then { _module = objectFromNetId _module; };
_syncedUnits = _syncedUnits apply { if (_x isEqualType "") then { objectFromNetId _x } else { _x } };
// Normalise the slot name so a stray leading/trailing space cannot split one logical slot into two
// keys that Save writes and Restore fails to find.
_slot = trim _slot;
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

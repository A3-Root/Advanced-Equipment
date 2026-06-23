#include "..\script_component.hpp"
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Overwrites a laptop's state with a snapshot produced by
 * AE3_armaos_fnc_laptop_captureState: broadcasts every saved variable (filesystem, user list,
 * calendar, mail, network config, handles, etc) onto the target, skipping the runtime/TEXT/CODE
 * variables, then rebuilds the command links and network bindings so the target is immediately
 * usable. Server-side. Used by the Restore Laptop Zeus module.
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The target laptop to overwrite
 * 1: _state <HASHMAP> - Snapshot from AE3_armaos_fnc_laptop_captureState
 *
 * Return Value:
 * <BOOL> - True when applied
 *
 * Example:
 * [_newLaptop, _state] call AE3_armaos_fnc_laptop_applyState;
 *
 * Public: No
 */

params ["_laptop", "_state"];

if (isNull _laptop || {isNil "_state"}) exitWith { false };

private _excluded = call AE3_armaos_fnc_laptop_stateVarsExcluded;
private _meta = ["AE3_OBJECT_TYPE", "AE3_ORIGINAL_POS", "AE3_ORIGINAL_DIR"];

{
    if !((_x in _excluded) || {_x in _meta}) then {
        private _value = _y;
        if (!isNil "_value") then {
            _laptop setVariable [_x, _value, true]; // broadcast so every client sees the restored data
        };
    };
} forEach _state;

// The restored filesystem replaces the previous one, so regenerate the runtime command links and
// re-bind the network device. Failures here must not abort the restore.
try {
    [_laptop] call AE3_armaos_fnc_link_init;
} catch {
    ERROR_2("applyState link_init failed for %1: %2",typeOf _laptop,_exception);
};

try {
    [_laptop] call AE3_network_fnc_initNetworkDevice;
} catch {
    ERROR_2("applyState initNetworkDevice failed for %1: %2",typeOf _laptop,_exception);
};

_laptop setVariable ["AE3_filesystemReady", true, true];

true

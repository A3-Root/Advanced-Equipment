// File: fnc_laptop_applyState.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
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

// Compare case-insensitively (snapshot keys are lower-cased by allVariables); otherwise the exclusion
// set never matches and non-serializable TEXT/CODE vars get broadcast.
private _excluded = (call AE3_armaos_fnc_laptop_stateVarsExcluded) apply { toLower _x };
private _meta = ["AE3_OBJECT_TYPE", "AE3_ORIGINAL_POS", "AE3_ORIGINAL_DIR"] apply { toLower _x };

// The filesystem and file pointer are large nested HashMaps (the filesystem also holds compiled CODE
// command files). A normal laptop keeps them SERVER-LOCAL and clients pull them on demand via
// getRemoteVar; broadcasting them publicly here queues a huge, partly non-serializable value for every
// client + JIP, which can stall the client's getRemoteVar chain so the userlist never arrives ->
// "Unknown user" / login timeout. So apply those two server-local (flag 2) and broadcast the rest.
private _serverLocalVars = ["ae3_filesystem", "ae3_filepointer"];

{
    private _key = toLower _x;
    if !((_key in _excluded) || {_key in _meta}) then {
        private _value = _y;
        if (!isNil "_value") then {
            private _syncFlag = [true, 2] select (_key in _serverLocalVars);
            // Guard each var so one bad value (e.g. a stray non-serializable var) can never abort the
            // whole restore and leave the userlist/filesystem unapplied.
            try {
                _laptop setVariable [_x, _value, _syncFlag];
            } catch {
                WARNING_2("applyState skipped var %1: %2",_x,_exception);
            };
        };
    };
} forEach _state;

// Ensure the userlist reaches clients even if they cached an empty list before the restore: re-broadcast
// and fire the same event AE3_armaos_fnc_computer_addUser uses so open sessions refresh.
private _userlist = _laptop getVariable ["AE3_Userlist", createHashMap];
_laptop setVariable ["AE3_Userlist", _userlist, true];
["ae3_computer_userAdded", [_laptop]] call CBA_fnc_globalEvent;

// The restored filesystem replaces the previous one, so regenerate the runtime command links.
// Failures here must not abort the restore.
try {
    [_laptop] call AE3_armaos_fnc_link_init;
} catch {
    ERROR_2("applyState link_init failed for %1: %2",typeOf _laptop,_exception);
};

// Re-bind the network device to its restored identity. Passing the saved parent/address makes
// initNetworkDevice reconnect to the same router with the same IP instead of resetting to loopback.
try {
    private _savedParent = _state getOrDefault ["ae3_network_parent", objNull];
    private _savedAddress = _state getOrDefault ["ae3_network_address", [127, 0, 0, 1]];
    [_laptop, _savedParent, _savedAddress] call AE3_network_fnc_initNetworkDevice;
} catch {
    ERROR_2("applyState initNetworkDevice failed for %1: %2",typeOf _laptop,_exception);
};

_laptop setVariable ["AE3_filesystemReady", true, true];

true

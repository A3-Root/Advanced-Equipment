#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Marks a device as fully initialized after all setup is complete.
 *
 * Arguments:
 * 0: _entity <STRING> - TODO: Add description
 * 1: _config <STRING> - TODO: Add description
 *
 * Return Value:
 * None
 *
 * Example:
 * [_entity, _config] call AE3_armaos_fnc_device_initComplete;
 *
 * Public: No
 */

params ["_entity", "_config"];

// Check if device was restored from inventory (already has filesystem)
// Only skip filesystem initialization if it exists AND is marked as ready
// This prevents issues with partial initialization from item restore
private _filesystem = _entity getVariable ["AE3_filesystem", nil];
private _wasRestored = !isNil "_filesystem" && {_filesystem isEqualType []};

if (!_wasRestored) then {
	// Fresh device - initialize filesystem first
	[_entity, _config] call AE3_filesystem_fnc_initFilesystem;
};

// (Re-)initialize OS command links (CODE references must be regenerated after item restore)
// and the network device. Exceptions here must not prevent the ready flag from being set,
// otherwise Zeus modules report "Filesystem not ready" forever (bug on dedicated servers).
try {
	[_entity] call AE3_armaos_fnc_link_init;
} catch {
	ERROR_2("link_init failed for %1: %2",typeOf _entity,_exception);
};

try {
	[_entity] call AE3_network_fnc_initNetworkDevice;
} catch {
	ERROR_2("initNetworkDevice failed for %1: %2",typeOf _entity,_exception);
};

// All initialization complete - now set the ready flag and capability flags
if (isServer) then {
	_entity setVariable ["AE3_cap_hasTerminal", true, true];
	_entity setVariable ["AE3_cap_hasFilesystem", true, true];
	_entity setVariable ["AE3_filesystemReady", true, true];

	// Notify listeners (e.g. the desktop addon's computer/media registry)
	["ae3_armaos_deviceReady", [_entity]] call CBA_fnc_localEvent;
};

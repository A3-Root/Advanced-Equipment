// File: fnc_module_crashDevice.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: 3DEN/Zeus/trigger handler for the AE3_CrashDevice module. Crashes every synced
 * AE3 laptop (blue screen until power-cycled) via AE3_power_fnc_crashDevice. No dialog - the
 * module acts on whatever AE3 devices it is synced to / placed on.
 *
 * Arguments:
 * 0: _module <OBJECT>
 * 1: _units <ARRAY>
 * 2: _activated <BOOL>
 *
 * Return Value:
 * true <BOOL>
 *
 * Public: No
 */

params ["_module", "_units", "_activated"];

if (!isServer) exitWith {};
if (!_activated) exitWith { true };

// Detect AE3 laptops the same way the intel modules do: by USB terminal config class or the
// runtime terminal capability flag. The device does not declare an "AE3_Device" config subclass,
// so filtering on that matched nothing and the module appeared to do nothing.
private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
private _objs = (synchronizedObjects _module) select { _x call _isLaptop };

// A curator drops this module directly onto a laptop, which spawns the module at the laptop's
// position without creating a synchronization link, so the synced-object list is empty. Fall back
// to the nearest laptop around the module so a placed-on-laptop module still finds its target.
if (_objs isEqualTo []) then
{
	private _near = (nearestObjects [_module, [], 3]) select { _x call _isLaptop };
	if (_near isNotEqualTo []) then { _objs = [_near select 0]; };
};

// When Zeus Enhanced is present and there is something to crash, confirm with the placing curator
// through a ZEN dialog first; the module stays alive until its confirm/cancel callback resolves.
if (EGVAR(main,hasZenDialog) && {_objs isNotEqualTo []}) exitWith
{
	[netId _module, _objs apply { netId _x }] remoteExec [QFUNC(zen_module_crashDevice), owner _module];
	true
};

{
	[_x] call AE3_power_fnc_crashDevice;
} forEach _objs;

// Report the outcome to the curator that placed the module.
private _title = localize "STR_AE3_Desktop_Config_CrashDeviceDisplayName";
private _msg = if (_objs isEqualTo []) then
{
	"No laptop found - sync the module to a laptop or drop it directly onto one."
}
else
{
	format ["Crashed %1 laptop(s).", count _objs]
};
[_title, _msg, 5] remoteExec ["BIS_fnc_curatorHint", owner _module];

deleteVehicle _module;

true

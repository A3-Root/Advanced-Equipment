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

if (_activated) then
{
	// Detect AE3 laptops the same way the intel modules do: by USB terminal config class or the
	// runtime terminal capability flag. The device does not declare an "AE3_Device" config subclass,
	// so filtering on that matched nothing and the module appeared to do nothing.
	private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
	private _objs = (synchronizedObjects _module) select { _x call _isLaptop };

	{
		[_x] call AE3_power_fnc_crashDevice;
	} forEach _objs;

	deleteVehicle _module;
};

true

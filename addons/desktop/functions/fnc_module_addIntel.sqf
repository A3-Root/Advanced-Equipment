#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: 3DEN/trigger handler for the AE3_AddIntel module. Reads the module attributes
 * and dispatches the intel to synced laptops or the laptop underneath the module.
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

// Zeus placement is handled by the curator dialog (fnc_zeus_module_addIntel);
// ignore the Eden/trigger path there to avoid a duplicate dispatch with empty fields.
if (_module getVariable ["BIS_fnc_moduleInit_isCuratorPlaced", false]) exitWith { false; };

if (!isServer) exitWith {};

if (_activated) then
{
	// The dynamic attribute control stores every field as one serialized array (see fnc_intel_3denSave).
	private _raw = _module getVariable ["AE3_ModuleIntel_Data", ""];
	private _data = switch (true) do
	{
		case (_raw isEqualType []): { _raw };
		case (_raw isEqualType "" && {_raw isNotEqualTo ""}): { parseSimpleArray _raw };
		default { [] };
	};
	_data params [
		["_type", "email"], ["_f1", ""], ["_f2", ""], ["_f3", ""], ["_f4", ""], ["_field5", "root"],
		["_createFrom", false], ["_createTo", false],
		["_oR", true], ["_oW", true], ["_oX", false], ["_eR", true], ["_eW", false], ["_eX", false]
	];

	// The sixth field is the body for most types, the owner for a locked file; the seventh carries
	// the email address-creation options for emails and the permission grid for everything else.
	private _arg6 = [_f4, _field5] select (_type isEqualTo "lockedfile");
	private _f7 = if (_type isEqualTo "email") then
	{
		[_field5, _createFrom, _createTo]
	}
	else
	{
		[[_oR, _oW, _oX], [_eR, _eW, _eX]]
	};

	private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
	private _laptops = (synchronizedObjects _module) select { _x call _isLaptop };

	if (_laptops isEqualTo []) then
	{
		private _nearby = nearestObjects [_module, [], 3] select { _x call _isLaptop };
		if (_nearby isNotEqualTo []) then { _laptops pushBack (_nearby select 0); };
	};

	{
		[_type, _x, _f1, _f2, _f3, _arg6, _f7] call AE3_desktop_fnc_intel_dispatch;
	} forEach _laptops;

	deleteVehicle _module;
};

true

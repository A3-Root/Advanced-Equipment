#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: 3DEN/trigger handler for typed intel modules. Reads the module attributes
 * and dispatches the intel to synced laptops.
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
	private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
	private _laptops = (synchronizedObjects _module) select { _x call _isLaptop };

	if (_laptops isEqualTo []) exitWith { deleteVehicle _module; };

	private _type = getText (configOf _module >> "ae3_intelType");
	private _f1 = "";
	private _f2 = "";
	private _f3 = "";
	private _arg6 = "";
	private _f7 = [[true, true, false], [true, false, false]];

	switch (_type) do
	{
		case "email":
		{
			_f1 = _module getVariable ["AE3_ModuleIntel_From", ""];
			_f2 = _module getVariable ["AE3_ModuleIntel_To", ""];
			_f3 = _module getVariable ["AE3_ModuleIntel_Subject", ""];
			_arg6 = _module getVariable ["AE3_ModuleIntel_Body", ""];
			_f7 = [
				_module getVariable ["AE3_ModuleIntel_Received", ""],
				_module getVariable ["AE3_ModuleIntel_CreateFrom", false],
				_module getVariable ["AE3_ModuleIntel_CreateTo", false]
			];
		};
		case "webpage":
		{
			_f1 = _module getVariable ["AE3_ModuleIntel_Url", ""];
			_f2 = _module getVariable ["AE3_ModuleIntel_Title", ""];
			_f3 = _module getVariable ["AE3_ModuleIntel_Content", ""];
		};
		case "history":
		{
			_f1 = _module getVariable ["AE3_ModuleIntel_Url", ""];
			_f2 = _module getVariable ["AE3_ModuleIntel_Time", ""];
		};
		case "media":
		{
			_f1 = _module getVariable ["AE3_ModuleIntel_Source", ""];
			_f2 = _module getVariable ["AE3_ModuleIntel_MediaType", "image"];
			_f3 = _module getVariable ["AE3_ModuleIntel_Dest", ""];
		};
		case "lockedfile":
		{
			_f1 = _module getVariable ["AE3_ModuleIntel_Dest", ""];
			_f2 = _module getVariable ["AE3_ModuleIntel_Password", ""];
			_f3 = _module getVariable ["AE3_ModuleIntel_Content", ""];
			_arg6 = _module getVariable ["AE3_ModuleIntel_Owner", "root"];
		};
		default
		{
			deleteVehicle _module;
			_type = "";
		};
	};

	{
		[_type, _x, _f1, _f2, _f3, _arg6, _f7] call AE3_desktop_fnc_intel_dispatch;
	} forEach (_laptops select {_type isNotEqualTo ""});

	deleteVehicle _module;
};

true

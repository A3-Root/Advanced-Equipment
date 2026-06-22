#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: 3DEN/trigger handler for the AE3_AddIntel module. Reads the module attributes
 * and dispatches the intel to laptops synced to the module (or all laptops when none synced).
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
	private _type = _module getVariable ["AE3_ModuleIntel_Type", "email"];
	private _f1 = _module getVariable ["AE3_ModuleIntel_Field1", ""];
	private _f2 = _module getVariable ["AE3_ModuleIntel_Field2", ""];
	private _f3 = _module getVariable ["AE3_ModuleIntel_Field3", ""];
	private _f4 = _module getVariable ["AE3_ModuleIntel_Field4", ""];
	private _owner = _module getVariable ["AE3_ModuleIntel_Owner", "root"];
	private _permissions = [
		[
			_module getVariable ["AE3_ModuleIntel_OwnerRead", true],
			_module getVariable ["AE3_ModuleIntel_OwnerWrite", true],
			_module getVariable ["AE3_ModuleIntel_OwnerExecute", false]
		],
		[
			_module getVariable ["AE3_ModuleIntel_EveryoneRead", true],
			_module getVariable ["AE3_ModuleIntel_EveryoneWrite", false],
			_module getVariable ["AE3_ModuleIntel_EveryoneExecute", false]
		]
	];

	private _laptops = (synchronizedObjects _module) select { isClass (configOf _x >> "AE3_Device") };

	if (_laptops isEqualTo []) then
	{
		[_type, "all", _f1, _f2, _f3, [_f4, _owner] select (_type isEqualTo "lockedfile"), _permissions] call AE3_desktop_fnc_intel_dispatch;
	}
	else
	{
		{
			[_type, _x, _f1, _f2, _f3, [_f4, _owner] select (_type isEqualTo "lockedfile"), _permissions] call AE3_desktop_fnc_intel_dispatch;
		} forEach _laptops;
	};

	deleteVehicle _module;
};

true

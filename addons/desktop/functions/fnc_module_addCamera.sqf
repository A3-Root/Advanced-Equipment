#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: 3DEN/trigger handler for the AE3_AddCamera module. Registers a CCTV feed for
 * each synced object using the module's name attribute. Zeus placement is handled by the
 * curator dialog (fnc_zeus_module_addCamera) and skipped here.
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

if (_module getVariable ["BIS_fnc_moduleInit_isCuratorPlaced", false]) exitWith { false };

if (!isServer) exitWith {};

if (_activated) then
{
	private _name = _module getVariable ["AE3_ModuleCamera_Name", "Camera"];
	private _objs = (synchronizedObjects _module) select { !(_x isKindOf "Logic") };

	{
		[_name, _x] call AE3_desktop_fnc_registerCamera;
	} forEach _objs;

	deleteVehicle _module;
};

true

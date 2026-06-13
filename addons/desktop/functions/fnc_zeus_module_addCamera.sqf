#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles the Zeus "Add Camera" module dialog (onLoad/onUnload). The camera view
 * originates from the object the module was placed on / synced to; the dialog only collects the
 * camera's display name. Registers the feed via AE3_desktop_fnc_registerCamera.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The module dialog
 * 1: _exitCode <NUMBER> - 1 = OK, 2 = Cancel
 * 2: _event <STRING> - "onLoad" or "onUnload"
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_display", "_exitCode", "_event"];

private _module = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];

/* ---------------------------------------- */

if (_event isEqualTo "onLoad") exitWith
{
	private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
	_mouseOver params ["_mouseOverType", "_mouseOverUnit"];

	private _object = objNull;
	if (_mouseOverType isEqualTo "OBJECT") then { _object = _mouseOverUnit; };
	_display setVariable ["AE3_cameraObject", _object];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
	if (_exitCode == 2) exitWith { deleteVehicle _module; };

	private _object = _display getVariable ["AE3_cameraObject", objNull];
	if (isNull _object) exitWith
	{
		[localize "STR_AE3_Desktop_Config_AddCameraDisplayName", localize "STR_AE3_Desktop_Access_NoCamera", 5] call BIS_fnc_curatorHint;
		deleteVehicle _module;
	};

	private _name = ctrlText (_display displayCtrl 1401);
	if (_name isEqualTo "") then { _name = "Camera"; };

	[_name, _object] call AE3_desktop_fnc_registerCamera;

	[localize "STR_AE3_Desktop_Config_AddCameraDisplayName", _name, 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

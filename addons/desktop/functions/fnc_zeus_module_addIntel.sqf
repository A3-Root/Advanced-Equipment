#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles the Zeus "Add Intel" module dialog (onLoad/onUnload). Placed on a
 * laptop, the intel targets that laptop; placed anywhere else it targets all laptops.
 * Field meanings switch with the selected type (see fnc_intel_dispatch).
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
	// Target laptop is optional: placed on a laptop -> that laptop, otherwise "all"
	private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
	_mouseOver params ["_mouseOverType", "_mouseOverUnit"];

	private _computer = objNull;
	if (_mouseOverType isEqualTo "OBJECT" && {isClass (configOf _mouseOverUnit >> "AE3_Device")}) then
	{
		_computer = _mouseOverUnit;
	};
	_display setVariable ["AE3_linkedComputer", _computer];

	private _combo = _display displayCtrl 1702;
	{
		_x params ["_typeId", "_label"];
		private _index = _combo lbAdd _label;
		_combo lbSetData [_index, _typeId];
	} forEach [
		["email", localize "STR_AE3_Desktop_Intel_Email"],
		["webpage", localize "STR_AE3_Desktop_Intel_Webpage"],
		["history", localize "STR_AE3_Desktop_Intel_History"],
		["calendar", localize "STR_AE3_Desktop_Intel_Calendar"],
		["media", localize "STR_AE3_Desktop_Intel_Media"],
		["lockedfile", localize "STR_AE3_Desktop_Intel_LockedFile"]
	];
	_combo lbSetCurSel 0;

	// Per-type field labels
	private _updateLabels = {
		params ["_combo"];
		private _display = ctrlParent _combo;
		private _type = _combo lbData (lbCurSel _combo);
		private _labels = switch (_type) do
		{
			case "webpage":  { [localize "STR_AE3_Desktop_Intel_LabelUrl", localize "STR_AE3_Desktop_Intel_LabelTitle", localize "STR_AE3_Desktop_Intel_LabelContent"] };
			case "history":  { [localize "STR_AE3_Desktop_Intel_LabelUrl", localize "STR_AE3_Desktop_Intel_LabelTime", ""] };
			case "calendar": { [localize "STR_AE3_Desktop_Intel_LabelDate", localize "STR_AE3_Desktop_Intel_LabelTitle", localize "STR_AE3_Desktop_Intel_LabelDetails"] };
			case "media":    { [localize "STR_AE3_Desktop_Intel_LabelSource", localize "STR_AE3_Desktop_Intel_LabelMediaType", localize "STR_AE3_Desktop_Intel_LabelDest"] };
			case "lockedfile": { [localize "STR_AE3_Desktop_Intel_LabelDest", localize "STR_AE3_Desktop_Intel_LabelPassword", localize "STR_AE3_Desktop_Intel_LabelContent"] };
			default          { [localize "STR_AE3_Desktop_Intel_LabelFrom", localize "STR_AE3_Desktop_Intel_LabelTo", localize "STR_AE3_Desktop_Intel_LabelSubject"] };
		};
		(_display displayCtrl 1710) ctrlSetText (_labels select 0);
		(_display displayCtrl 1711) ctrlSetText (_labels select 1);
		(_display displayCtrl 1712) ctrlSetText (_labels select 2);
		private _isEmail = _type isEqualTo "email";
		private _isLocked = _type isEqualTo "lockedfile";
		(_display displayCtrl 1713) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelBody");
		{
			(_display displayCtrl _x) ctrlShow _isEmail;
		} forEach [1713, 1404];
		{
			(_display displayCtrl _x) ctrlShow _isLocked;
		} forEach [1714, 1405, 1715, 1716, 1301, 1302, 1303, 1304, 1305, 1306];
	};

	[_combo] call _updateLabels;
	_combo setVariable ["AE3_updateLabels", _updateLabels];
	_combo ctrlAddEventHandler ["LBSelChanged", {
		params ["_combo"];
		[_combo] call (_combo getVariable "AE3_updateLabels");
	}];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
	if (_exitCode == 2) exitWith { deleteVehicle _module; };

	private _computer = _display getVariable ["AE3_linkedComputer", objNull];
	private _target = if (isNull _computer) then { "all" } else { netId _computer };

	private _combo = _display displayCtrl 1702;
	private _type = _combo lbData (lbCurSel _combo);

	[
		_type,
		_target,
		ctrlText (_display displayCtrl 1401),
		ctrlText (_display displayCtrl 1402),
		ctrlText (_display displayCtrl 1403),
		[ctrlText (_display displayCtrl 1404), ctrlText (_display displayCtrl 1405)] select (_type isEqualTo "lockedfile"),
		[
			[
				cbChecked (_display displayCtrl 1301),
				cbChecked (_display displayCtrl 1302),
				cbChecked (_display displayCtrl 1303)
			],
			[
				cbChecked (_display displayCtrl 1304),
				cbChecked (_display displayCtrl 1305),
				cbChecked (_display displayCtrl 1306)
			]
		]
	] call AE3_desktop_fnc_intel_dispatch;

	[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", format ["%1 -> %2", _type, [localize "STR_AE3_Desktop_Intel_TargetAll", [_computer] call FUNC(deviceLabel)] select (!isNull _computer)], 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

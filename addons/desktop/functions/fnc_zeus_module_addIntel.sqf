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
		// email-only: body field
		{
			(_display displayCtrl _x) ctrlShow _isEmail;
		} forEach [1713, 1404];
		// shared: received-time row (email) / owner-name row (lockedfile)
		{
			(_display displayCtrl _x) ctrlShow (_isEmail || _isLocked);
		} forEach [1714, 1405];
		// email-only: sender/recipient address creation checkboxes and labels
		{
			(_display displayCtrl _x) ctrlShow _isEmail;
		} forEach [1717, 1317, 1718, 1318];
		{
			(_display displayCtrl _x) ctrlEnable _isEmail;
		} forEach [1317, 1318];
		// lockedfile-only: permission column headers and all six permission checkboxes
		{
			(_display displayCtrl _x) ctrlShow _isLocked;
		} forEach [1715, 1716, 1301, 1302, 1303, 1304, 1305, 1306];
		if (_isEmail) then
		{
			(_display displayCtrl 1714) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelReceivedTime");
			(_display displayCtrl 1717) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelCreateFromHandle");
			(_display displayCtrl 1718) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelCreateToHandle");
			(_display displayCtrl 1405) ctrlSetText "";
			(_display displayCtrl 1317) cbSetChecked false;
			(_display displayCtrl 1318) cbSetChecked false;
			// Derive one grid-row height from the y gap between body label (IDC 1713, y=11.2) and
			// body field (IDC 1404, y=12.2) — avoids using the all-caps GUI_GRID_* preprocessor macros.
			private _pLabel = ctrlPosition (_display displayCtrl 1713);
			private _pBody  = ctrlPosition (_display displayCtrl 1404);
			private _gH = (_pBody select 1) - (_pLabel select 1); // 1 grid row
			// Shrink body to h=2 rows so the received-time row fits directly below before the checkboxes.
			(_display displayCtrl 1404) ctrlSetPosition [_pBody select 0, _pBody select 1, _pBody select 2, 2 * _gH];
			(_display displayCtrl 1404) ctrlCommit 0;
			private _rowY = (_pBody select 1) + (2.3 * _gH);
			private _p14 = ctrlPosition (_display displayCtrl 1714);
			private _p15 = ctrlPosition (_display displayCtrl 1405);
			(_display displayCtrl 1714) ctrlSetPosition [_p14 select 0, _rowY, _p14 select 2, _p14 select 3];
			(_display displayCtrl 1405) ctrlSetPosition [_p15 select 0, _rowY, _p15 select 2, _p15 select 3];
			(_display displayCtrl 1714) ctrlCommit 0;
			(_display displayCtrl 1405) ctrlCommit 0;
		};
		if (_isLocked) then
		{
			(_display displayCtrl 1714) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelOwner");
			(_display displayCtrl 1715) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelOwner");
			(_display displayCtrl 1716) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelEveryone");
			// Restore owner row to its config-defined position (y=13.2, which is body_y + 1 grid row).
			private _pLabel = ctrlPosition (_display displayCtrl 1713);
			private _pBody  = ctrlPosition (_display displayCtrl 1404);
			private _gH = (_pBody select 1) - (_pLabel select 1);
			private _origY = (_pBody select 1) + _gH; // config-defined y=13.2 = body_y + 1 * gridH
			private _p14 = ctrlPosition (_display displayCtrl 1714);
			private _p15 = ctrlPosition (_display displayCtrl 1405);
			(_display displayCtrl 1714) ctrlSetPosition [_p14 select 0, _origY, _p14 select 2, _p14 select 3];
			(_display displayCtrl 1405) ctrlSetPosition [_p15 select 0, _origY, _p15 select 2, _p15 select 3];
			(_display displayCtrl 1714) ctrlCommit 0;
			(_display displayCtrl 1405) ctrlCommit 0;
		};
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

	private _f5 = if (_type isEqualTo "email") then
	{
		[ctrlText (_display displayCtrl 1405), cbChecked (_display displayCtrl 1317), cbChecked (_display displayCtrl 1318)]
	}
	else
	{
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
	};

	[
		_type,
		_target,
		ctrlText (_display displayCtrl 1401),
		ctrlText (_display displayCtrl 1402),
		ctrlText (_display displayCtrl 1403),
		[ctrlText (_display displayCtrl 1404), ctrlText (_display displayCtrl 1405)] select (_type isEqualTo "lockedfile"),
		_f5
	] call AE3_desktop_fnc_intel_dispatch;

	[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", format ["%1 -> %2", _type, [localize "STR_AE3_Desktop_Intel_TargetAll", [_computer] call FUNC(deviceLabel)] select (!isNull _computer)], 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

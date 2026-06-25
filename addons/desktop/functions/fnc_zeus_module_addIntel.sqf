#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles the Zeus "Add Intel" module dialog (onLoad/onUnload). Placed on a
 * laptop, the intel targets that laptop; placed anywhere else it is ignored.
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
	private _isLaptop = { isClass (configOf _this >> "AE3_USB_Interface") || {_this getVariable ["AE3_cap_hasTerminal", false]} };
	private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
	_mouseOver params ["_mouseOverType", "_mouseOverUnit"];

	private _computer = objNull;
	if (_mouseOverType isEqualTo "OBJECT" && {_mouseOverUnit call _isLaptop}) then
	{
		_computer = _mouseOverUnit;
	};
	_display setVariable ["AE3_linkedComputer", _computer];

	// Populate the type/media combos and lay out the fields for the initial type, then keep the
	// layout in sync as the type changes. The same helpers drive the 3DEN module attribute control.
	[_display] call AE3_desktop_fnc_intel_initFields;
	[_display] call AE3_desktop_fnc_intel_updateFields;

	(_display displayCtrl 1702) ctrlAddEventHandler ["LBSelChanged", {
		params ["_combo"];
		[ctrlParent _combo] call AE3_desktop_fnc_intel_updateFields;
	}];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
	if (_exitCode == 2) exitWith { deleteVehicle _module; };

	private _computer = _display getVariable ["AE3_linkedComputer", objNull];
	if (isNull _computer) exitWith
	{
		[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", "Place the module on a laptop.", 5] call BIS_fnc_curatorHint;
		deleteVehicle _module;
	};
	private _target = netId _computer;

	private _combo = _display displayCtrl 1702;
	private _type = _combo lbData (lbCurSel _combo);

	// For media the second field is taken from the kind dropdown; every other type reads the edit.
	private _field2 = if (_type isEqualTo "media") then
	{
		private _mediaCombo = _display displayCtrl 1602;
		_mediaCombo lbData (lbCurSel _mediaCombo)
	}
	else
	{
		ctrlText (_display displayCtrl 1402)
	};

	// Sixth dispatch field: email/webpage/history -> body edit; lockedfile -> owner; media -> the
	// mod/mission path hint taken from the "source is a mod path" checkbox (IDC 1318).
	private _arg6 = switch (_type) do
	{
		case "lockedfile": { ctrlText (_display displayCtrl 1405) };
		case "media":      { ["mission", "mod"] select (cbChecked (_display displayCtrl 1318)) };
		default            { ctrlText (_display displayCtrl 1404) };
	};

	// Seventh dispatch field: email -> [receivedTime, createFrom, createTo]; media -> experimental
	// "try web viewer" toggle (IDC 1317); lockedfile/others -> the permission grid.
	private _f5 = switch (_type) do
	{
		case "email":
		{
			[ctrlText (_display displayCtrl 1405), cbChecked (_display displayCtrl 1317), cbChecked (_display displayCtrl 1318)]
		};
		case "media":
		{
			cbChecked (_display displayCtrl 1317)
		};
		default
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
	};

	[
		_type,
		_target,
		ctrlText (_display displayCtrl 1401),
		_field2,
		ctrlText (_display displayCtrl 1403),
		_arg6,
		_f5
	] call AE3_desktop_fnc_intel_dispatch;

	[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", format ["%1 -> %2", _type, [localize "STR_AE3_Desktop_Intel_TargetAll", [_computer] call FUNC(deviceLabel)] select (!isNull _computer)], 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

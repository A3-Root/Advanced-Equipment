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
	private _override = uiNamespace getVariable ["AE3_desktop_intelZenOverride", []];

	// Standalone per-type modules (AE3_AddEmail/AddWebpage/... - see CfgVehicles) carry an
	// ae3_intelType; the unified module leaves it empty and shows the type picker instead.
	private _forcedType = getText (configOf _module >> "ae3_intelType");

	// ZEN path: hand the module to the ZEN dialog, unless we are being reopened by that dialog for a
	// media/lockedfile type, which still needs the legacy filesystem Browse UI.
	if (_override isEqualTo [] && EGVAR(main,hasZenDialog)) exitWith
	{
		private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
		_mouseOver params ["_mouseOverType", "_mouseOverUnit"];
		private _computer = objNull;
		if (_mouseOverType isEqualTo "OBJECT" && {_mouseOverUnit call _isLaptop}) then { _computer = _mouseOverUnit; };

		_module setVariable [QGVAR(zenHandled), true];
		_display closeDisplay 2;

		switch (true) do
		{
			// media/lockedfile keep the legacy Browse dialog (reopened preset+locked to their type)
			case (_forcedType in ["media", "lockedfile"]):
			{
				[{
					params ["_module", "_computer"];
					missionNamespace setVariable ["BIS_fnc_initCuratorAttributes_target", _module];
					uiNamespace setVariable ["AE3_desktop_intelZenOverride", [_module, _computer]];
					_module setVariable [QGVAR(zenHandled), false];
					createDialog "AE3_UserInterface_Zeus_Module_AddIntel";
				}, [_module, _computer]] call CBA_fnc_execNextFrame;
			};
			// a fixed email/webpage/history type skips the picker and opens step 2 directly
			case (_forcedType isNotEqualTo ""):
			{
				[FUNC(zen_module_addIntel_step2), [_module, _computer, _forcedType]] call CBA_fnc_execNextFrame;
			};
			// unified module: the two-step ZEN flow starting at the type picker
			default
			{
				[FUNC(zen_module_addIntel), [_module, _computer]] call CBA_fnc_execNextFrame;
			};
		};
	};

	private _computer = objNull;
	if (_override isNotEqualTo []) then
	{
		// Reopened from the ZEN dialog: use the laptop it already resolved and consume the override.
		_computer = _override select 1;
		uiNamespace setVariable ["AE3_desktop_intelZenOverride", []];
	}
	else
	{
		private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
		_mouseOver params ["_mouseOverType", "_mouseOverUnit"];
		if (_mouseOverType isEqualTo "OBJECT" && {_mouseOverUnit call _isLaptop}) then { _computer = _mouseOverUnit; };
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

	// Standalone module: lock the type picker to this module's fixed intel type.
	if (_forcedType isNotEqualTo "") then
	{
		private _combo = _display displayCtrl 1702;
		for "_i" from 0 to (lbSize _combo - 1) do
		{
			if ((_combo lbData _i) isEqualTo _forcedType) exitWith { _combo lbSetCurSel _i; };
		};
		[_display] call AE3_desktop_fnc_intel_updateFields;
		_combo ctrlEnable false;
	};
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
	if (_module getVariable [QGVAR(zenHandled), false]) exitWith {}; // ZEN owns the lifecycle
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

	// Fifth dispatch field (destination path). For media the third field is the destination folder
	// (field 1403) and the file name comes from the reused row (field 1405); combine them.
	private _field3 = if (_type isEqualTo "media") then
	{
		private _folder = ctrlText (_display displayCtrl 1403);
		private _fname = ctrlText (_display displayCtrl 1405);
		if (_fname isEqualTo "") then { _folder } else { (_folder + "/" + _fname) regexReplace ["/+", "/"] }
	}
	else
	{
		ctrlText (_display displayCtrl 1403)
	};

	// Media with base64 pasted into the image box: route as an inline picture (stored as a data-URL
	// marker for the web viewer) instead of registering a real texture path. The box overrides the
	// source-path field; the folder + file name still form the filesystem destination (_field3).
	private _dispatchType = _type;
	private _f1 = ctrlText (_display displayCtrl 1401);
	if (_type isEqualTo "media") then
	{
		private _b64 = ctrlText (_display displayCtrl 1420);
		if ((trim _b64) isNotEqualTo "") then
		{
			if ((count _b64) > AE3_MAX_PICTURE_B64) exitWith
			{
				[objNull, localize "STR_AE3_Main_Zeus_PictureTooLarge"] call BIS_fnc_showCuratorFeedbackMessage;
				deleteVehicle _module;
			};
			_dispatchType = "picture";
			_f1 = _b64;
		};
	};

	[
		_dispatchType,
		_target,
		_f1,
		_field2,
		_field3,
		_arg6,
		_f5
	] call AE3_desktop_fnc_intel_dispatch;

	[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", format ["%1 -> %2", _type, [localize "STR_AE3_Desktop_Intel_TargetAll", [_computer] call FUNC(deviceLabel)] select (!isNull _computer)], 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

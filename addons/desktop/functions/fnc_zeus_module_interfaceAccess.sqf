#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles the Zeus "Interface & Access" module dialog (onLoad/onUnload). Place
 * the module ON a laptop. Lets the mission maker pick the laptop's interface mode and grant
 * each connected player - and, as a fallback for everyone else (incl. JIP), each side - access
 * to CLI, GUI, Both or None. Builds the per-interface access conditions consumed by
 * AE3_desktop_fnc_canAccessInterface and applies them via AE3_desktop_fnc_setInterfaceAccess.
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

// data/label pairs reused by the combos
private _modeOptions = [
	["default", localize "STR_AE3_Desktop_Access_ModeDefault"],
	["cli", localize "STR_AE3_Desktop_Access_CLI"],
	["gui", localize "STR_AE3_Desktop_Access_GUI"],
	["both", localize "STR_AE3_Desktop_Access_Both"]
];
private _accessOptions = [
	["none", localize "STR_AE3_Desktop_Access_None"],
	["cli", localize "STR_AE3_Desktop_Access_CLI"],
	["gui", localize "STR_AE3_Desktop_Access_GUI"],
	["both", localize "STR_AE3_Desktop_Access_Both"]
];

/* ---------------------------------------- */

if (_event isEqualTo "onLoad") exitWith
{
	// Target laptop: the module must be placed on a laptop (per-laptop scope)
	private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
	_mouseOver params ["_mouseOverType", "_mouseOverUnit"];

	private _computer = objNull;
	if (_mouseOverType isEqualTo "OBJECT" && {isClass (configOf _mouseOverUnit >> "AE3_Device")}) then
	{
		_computer = _mouseOverUnit;
	};
	_display setVariable ["AE3_linkedComputer", _computer];

	// Hand off to ZEN's Dynamic Dialog when Zeus Enhanced is present.
	if (EGVAR(main,hasZenDialog)) exitWith
	{
		_module setVariable [QGVAR(zenHandled), true];
		_display closeDisplay 2;
		if (isNull _computer) exitWith
		{
			[localize "STR_AE3_Desktop_Config_InterfaceAccessDisplayName", localize "STR_AE3_Desktop_Access_NoLaptop", 5] call BIS_fnc_curatorHint;
			deleteVehicle _module;
		};
		[FUNC(zen_module_interfaceAccess), [_module, _computer]] call CBA_fnc_execNextFrame;
	};

	_display setVariable ["AE3_access", createHashMap];
	_display setVariable ["AE3_names", createHashMap];

	private _fillCombo = {
		params ["_combo", "_opts", "_sel"];
		{
			_x params ["_data", "_label"];
			private _i = _combo lbAdd _label;
			_combo lbSetData [_i, _data];
		} forEach _opts;
		_combo lbSetCurSel _sel;
	};

	// Interface mode combo (default = Both)
	[_display displayCtrl 1730, _modeOptions, 3] call _fillCombo;

	// Side fallback combos (default = Both, i.e. parity with the global default)
	{
		[_display displayCtrl _x, _accessOptions, 3] call _fillCombo;
	} forEach [1750, 1752, 1754, 1756];

	// Player list (one row per connected human; default access Both)
	private _lb = _display displayCtrl 1740;
	private _access = _display getVariable "AE3_access";
	private _names = _display getVariable "AE3_names";
	{
		private _uid = getPlayerUID _x;
		if (_uid isEqualTo "") then { continue };
		_access set [_uid, "both"];
		_names set [_uid, name _x];
		private _row = _lb lbAdd format ["[%1] %2", localize "STR_AE3_Desktop_Access_Both", name _x];
		_lb lbSetData [_row, _uid];
	} forEach (allPlayers - entities "HeadlessClient_F");

	// Access buttons: set the highlighted player's access and refresh its row label
	private _btnHandler = {
		params ["_ctrl"];
		private _disp = ctrlParent _ctrl;
		private _data = switch (ctrlIDC _ctrl) do
		{
			case 1741: { ["cli", localize "STR_AE3_Desktop_Access_CLI"] };
			case 1742: { ["gui", localize "STR_AE3_Desktop_Access_GUI"] };
			case 1743: { ["both", localize "STR_AE3_Desktop_Access_Both"] };
			default    { ["none", localize "STR_AE3_Desktop_Access_None"] };
		};
		_data params ["_access", "_label"];

		private _lb = _disp displayCtrl 1740;
		private _sel = lbCurSel _lb;
		if (_sel < 0) exitWith {};
		private _uid = _lb lbData _sel;
		(_disp getVariable "AE3_access") set [_uid, _access];
		_lb lbSetText [_sel, format ["[%1] %2", _label, (_disp getVariable "AE3_names") get _uid]];
	};
	{
		(_display displayCtrl _x) ctrlAddEventHandler ["ButtonClick", _btnHandler];
	} forEach [1741, 1742, 1743, 1744];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
	if (_module getVariable [QGVAR(zenHandled), false]) exitWith {}; // ZEN owns the lifecycle
	if (_exitCode == 2) exitWith { deleteVehicle _module; };

	private _computer = _display getVariable ["AE3_linkedComputer", objNull];
	if (isNull _computer) exitWith
	{
		[localize "STR_AE3_Desktop_Config_InterfaceAccessDisplayName", localize "STR_AE3_Desktop_Access_NoLaptop", 5] call BIS_fnc_curatorHint;
		deleteVehicle _module;
	};

	// Interface mode
	private _mode = (_display displayCtrl 1730) lbData (lbCurSel (_display displayCtrl 1730));
	if (_mode isNotEqualTo "default") then
	{
		[_computer, _mode] call AE3_desktop_fnc_setInterfaceMode;
	};

	// Per-player decisions
	private _map = _display getVariable ["AE3_access", createHashMap];
	private _playerPairs = [];
	{
		_playerPairs pushBack [_x, _map get _x];
	} forEach keys _map;

	// Per-side fallback (str (side group _p) yields WEST / EAST / GUER / CIV)
	private _sidePairs = [
		["WEST", (_display displayCtrl 1750) lbData (lbCurSel (_display displayCtrl 1750))],
		["EAST", (_display displayCtrl 1752) lbData (lbCurSel (_display displayCtrl 1752))],
		["GUER", (_display displayCtrl 1754) lbData (lbCurSel (_display displayCtrl 1754))],
		["CIV",  (_display displayCtrl 1756) lbData (lbCurSel (_display displayCtrl 1756))]
	];

	// Authoritative per-player, then per-side fallback. Compiled with the tables inlined so
	// the condition is self-contained (setInterfaceAccess stores it as a public, JIP-safe var).
	private _mkCond = {
		params ["_iface"];
		compile format [
			"params ['_l', '_p']; private _pa = %1; private _sa = %2; private _ic = %3; private _u = getPlayerUID _p; private _a = ''; { if ((_x select 0) isEqualTo _u) exitWith { _a = _x select 1 } } forEach _pa; if (_a isEqualTo '') then { private _sn = str (side group _p); { if ((_x select 0) isEqualTo _sn) exitWith { _a = _x select 1 } } forEach _sa }; _a in _ic",
			str _playerPairs, str _sidePairs, str [_iface, "both"]
		]
	};

	[_computer, "cli", ["cli"] call _mkCond] call AE3_desktop_fnc_setInterfaceAccess;
	[_computer, "gui", ["gui"] call _mkCond] call AE3_desktop_fnc_setInterfaceAccess;

	[localize "STR_AE3_Desktop_Config_InterfaceAccessDisplayName", format ["%1: %2", localize "STR_AE3_Desktop_Access_Applied", [_computer] call FUNC(deviceLabel)], 5] call BIS_fnc_curatorHint;

	deleteVehicle _module;
};

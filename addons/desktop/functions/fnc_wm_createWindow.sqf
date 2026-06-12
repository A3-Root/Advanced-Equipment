#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Creates a desktop window for an application and runs its entry function.
 * The window is a dynamically created controls group with titlebar (drag handle), close
 * button and themed body. The app entry is called as [_winId, _ctrlGroup, _computer, _args]
 * and may return a HASHMAP with optional "onClose" CODE callback.
 *
 * Arguments:
 * 0: _appClass <STRING> - App id (CfgAE3Apps class name or runtime-registered id)
 * 1: _args <ANY> (Optional, default: []) - Passed to the app entry function
 *
 * Return Value:
 * Window id, -1 on failure <NUMBER>
 *
 * Example:
 * ["Files"] call AE3_desktop_fnc_wm_createWindow;
 *
 * Public: Yes
 */

params ["_appClass", ["_args", []]];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _computer = _session getOrDefault ["computer", objNull];

if (isNull _display) exitWith { -1 };

private _apps = [] call AE3_desktop_fnc_app_list;
private _appIndex = _apps findIf { (_x select 0) isEqualTo _appClass };
if (_appIndex == -1) exitWith { -1 };

(_apps select _appIndex) params ["", "_displayName", "_entry", "_sizeW", "_sizeH", "", "_singleton"];

private _windows = _session get "windows";

// Singleton apps: only one window instance
private _existing = -1;
if (_singleton) then
{
	{
		if ((_y getOrDefault ["app", ""]) isEqualTo _appClass) exitWith { _existing = _x; };
	} forEach _windows;
};
if (_existing != -1) exitWith { _existing };

private _theme = _session get "theme";
private _winId = _session get "nextWinId";
_session set ["nextWinId", _winId + 1];

// Cascade new windows
private _w = safeZoneW * _sizeW;
private _h = safeZoneH * _sizeH;
private _x = safeZoneX + 0.18 + 0.02 * (_winId mod 8);
private _y = safeZoneY + 0.06 + 0.02 * (_winId mod 8);

private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_group ctrlSetPosition [_x, _y, _w, _h];
_group ctrlCommit 0;

/* ---------------------------------------- */

private _body = _display ctrlCreate ["RscText", -1, _group];
_body ctrlSetPosition [0, 0, _w, _h];
_body ctrlSetBackgroundColor (_theme get "window");
_body ctrlCommit 0;

private _titlebar = _display ctrlCreate ["RscButton", -1, _group];
_titlebar ctrlSetPosition [0, 0, _w - 0.05, 0.04];
_titlebar ctrlSetText _displayName;
_titlebar ctrlSetBackgroundColor (_theme get "titlebar");
_titlebar ctrlSetTextColor (_theme get "text");
_titlebar ctrlCommit 0;

private _closeBtn = _display ctrlCreate ["RscButton", -1, _group];
_closeBtn ctrlSetPosition [_w - 0.05, 0, 0.05, 0.04];
_closeBtn ctrlSetText "X";
_closeBtn ctrlSetBackgroundColor (_theme get "accent");
_closeBtn ctrlSetTextColor (_theme get "text");
_closeBtn ctrlCommit 0;

/* ---------------------------------------- */
/* Drag start (display-level MouseMoving/Up handlers do the actual move) */

_titlebar setVariable ["AE3_winGroup", _group];
_titlebar ctrlAddEventHandler ["MouseButtonDown", {
	params ["_ctrl", "_button", "_xPos", "_yPos"];
	if (_button != 0) exitWith {};
	if (!(missionNamespace getVariable ["AE3_Desktop_EnableDragDrop", true])) exitWith {};

	private _group = _ctrl getVariable "AE3_winGroup";
	private _pos = ctrlPosition _group;

	private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
	_session set ["drag", [_group, _xPos - (_pos select 0), _yPos - (_pos select 1)]];
}];

_closeBtn setVariable ["AE3_winId", _winId];
_closeBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	[_button getVariable "AE3_winId"] call AE3_desktop_fnc_wm_closeWindow;
}];

/* ---------------------------------------- */
/* Run the app entry */

private _entryFnc = missionNamespace getVariable [_entry, {}];
private _callbacks = [_winId, _group, _computer, _args] call _entryFnc;
if (isNil "_callbacks") then { _callbacks = createHashMap; };
if (!(_callbacks isEqualType createHashMap)) then { _callbacks = createHashMap; };

_windows set [_winId, createHashMapFromArray [
	["app", _appClass],
	["group", _group],
	["callbacks", _callbacks]
]];

_winId

// File: fnc_wm_updateTaskbar.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Rebuilds the taskbar buttons for all open desktop windows. The active, non-minimized
 * window is highlighted with the theme accent. Runs on the operator client only (no network traffic).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call AE3_desktop_fnc_wm_updateTaskbar;
 *
 * Public: No
 */

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
if (isNull _display) exitWith {};

private _theme = _session getOrDefault ["theme", createHashMap];

// Clear previous taskbar buttons
{ ctrlDelete _x; } forEach (_session getOrDefault ["taskBtns", []]);

private _windows = _session getOrDefault ["windows", createHashMap];
private _activeWin = _session getOrDefault ["activeWin", -1];
private _btns = [];
private _i = 0;

{
	private _winId = _x;
	private _win = _y;

	private _btn = _display ctrlCreate ["RscButton", -1];
	_btn ctrlSetPosition [safeZoneX + 0.42 + 0.135 * _i, safeZoneY + safeZoneH - 0.038, 0.13, 0.036];
	_btn ctrlSetText (_win getOrDefault ["title", "Window"]);

	private _isActive = (_winId isEqualTo _activeWin) && {!(_win getOrDefault ["minimized", false])};
	_btn ctrlSetBackgroundColor (_theme getOrDefault [["titlebar", "accent"] select _isActive, [0.18, 0.20, 0.24, 1]]);
	_btn ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
	_btn ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
	_btn ctrlCommit 0;

	_btn setVariable ["AE3_winId", _winId];
	_btn ctrlAddEventHandler ["ButtonClick", {
		[_this select 0 getVariable "AE3_winId"] call AE3_desktop_fnc_wm_focusWindow;
	}];

	_btns pushBack _btn;
	_i = _i + 1;
} forEach _windows;

_session set ["taskBtns", _btns];

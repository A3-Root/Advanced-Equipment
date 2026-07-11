// File: fnc_wm_minimizeWindow.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Minimizes (hides) or restores (shows) a desktop window. Hiding the window's control
 * group hides all of its child controls. The window remains tracked and accessible via the taskbar.
 *
 * Arguments:
 * 0: _winId <NUMBER> - Window id
 * 1: _min <BOOL> (Optional, default: true) - true to minimize, false to restore
 *
 * Return Value:
 * None
 *
 * Example:
 * [_winId, true] call AE3_desktop_fnc_wm_minimizeWindow;
 *
 * Public: No
 */

params ["_winId", ["_min", true]];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _windows = _session getOrDefault ["windows", createHashMap];
private _win = _windows getOrDefault [_winId, nil];
if (isNil "_win") exitWith {};

(_win get "group") ctrlShow !_min;
_win set ["minimized", _min];

if (_min && {(_session getOrDefault ["activeWin", -1]) isEqualTo _winId}) then
{
	_session set ["activeWin", -1];
};

[] call AE3_desktop_fnc_wm_updateTaskbar;

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Marks a desktop window as the active one and restores it if it was minimized.
 * Note: the Arma UI engine renders dynamically created control groups in creation order and offers
 * no z-order reordering, so "focus" restores + highlights the window rather than raising it.
 *
 * Arguments:
 * 0: _winId <NUMBER> - Window id
 *
 * Return Value:
 * None
 *
 * Example:
 * [_winId] call AE3_desktop_fnc_wm_focusWindow;
 *
 * Public: No
 */

params ["_winId"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _windows = _session getOrDefault ["windows", createHashMap];
private _win = _windows getOrDefault [_winId, nil];
if (isNil "_win") exitWith {};

if (_win getOrDefault ["minimized", false]) then
{
	(_win get "group") ctrlShow true;
	_win set ["minimized", false];
};

_session set ["activeWin", _winId];
[] call AE3_desktop_fnc_wm_updateTaskbar;

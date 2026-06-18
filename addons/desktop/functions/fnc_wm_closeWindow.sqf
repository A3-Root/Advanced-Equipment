#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Closes a desktop window: runs the app's onClose callback and deletes the
 * window's controls group.
 *
 * Arguments:
 * 0: _winId <NUMBER> - Window id returned by wm_createWindow
 *
 * Return Value:
 * None
 *
 * Example:
 * [_winId] call AE3_desktop_fnc_wm_closeWindow;
 *
 * Public: Yes
 */

params ["_winId"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _windows = _session getOrDefault ["windows", createHashMap];
private _window = _windows getOrDefault [_winId, nil];

if (isNil "_window") exitWith {};

private _callbacks = _window getOrDefault ["callbacks", createHashMap];
private _onClose = _callbacks getOrDefault ["onClose", {}];
[_winId, _session getOrDefault ["computer", objNull]] call _onClose;

ctrlDelete (_window get "group");
_windows deleteAt _winId;

if ((_session getOrDefault ["activeWin", -1]) isEqualTo _winId) then
{
	_session set ["activeWin", -1];
};

[] call AE3_desktop_fnc_wm_updateTaskbar;

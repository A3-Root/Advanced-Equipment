#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Terminal" app: opens the full classic CLI terminal on top of the
 * desktop. All existing CLI commands (including third-party filesystem executables, ssh, msg)
 * work unchanged. When the terminal closes, control returns to the desktop and the laptop
 * lock (mutex) is re-claimed for the desktop session.
 *
 * Arguments:
 * 0: _winId <NUMBER>
 * 1: _ctrlGroup <CONTROL>
 * 2: _computer <OBJECT>
 * 3: _args <ANY>
 *
 * Return Value:
 * App callbacks <HASHMAP>
 *
 * Public: No
 */

params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _desktopDisplay = _session getOrDefault ["display", displayNull];

// The terminal is a fullscreen child display of the desktop, not an in-window app -
// close this (empty) window immediately and launch the terminal display instead
[{ [_this select 0] call AE3_desktop_fnc_wm_closeWindow; }, [_winId]] call CBA_fnc_execNextFrame;

private _terminalDisplay = _desktopDisplay createDisplay "AE3_ArmaOS_Main_Dialog";

[_computer, _terminalDisplay] spawn AE3_armaos_fnc_terminal_init;

// The terminal's own Unload handler releases the mutex and reports "not in use" - re-claim
// both for the still-open desktop session afterwards (handlers run in registration order)
_terminalDisplay displayAddEventHandler ["Unload", {
	private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
	private _computer = _session getOrDefault ["computer", objNull];
	if (isNull _computer) exitWith {};

	_computer setVariable ["AE3_computer_mutex", _session getOrDefault ["player", player], true];
	[_computer, "inUse", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];

	// Desktop lock screen again (terminal unload does not know about the desktop)
	_computer setObjectTextureGlobal [1, "#(argb,8,8,3)color(0.05,0.08,0.12,1,co)"];
}];

createHashMap

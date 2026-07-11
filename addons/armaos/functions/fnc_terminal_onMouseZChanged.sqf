// File: fnc_terminal_onMouseZChanged.sqf
#include "..\script_component.hpp"
/*
 * Author: Root, Wasserstoff, y0014984
 * Description: MouseZChanged (scroll wheel) handler for the terminal console control.
 *
 * Arguments:
 * 0: _displayorcontrol <CONTROL> - The terminal output control
 * 1: _scroll <NUMBER> - Scroll delta
 *
 * Return Value:
 * None
 *
 * Example:
 * _terminalCtrl ctrlAddEventHandler ["MouseZChanged", { _this call AE3_armaos_fnc_terminal_onMouseZChanged }];
 *
 * Public: No
 */

params ["_displayorcontrol", "_scroll"];

private _computer = _displayorcontrol getVariable "AE3_computer";
private _terminal = _computer getVariable "AE3_terminal";
private _terminalScrollPosition = _terminal get "AE3_terminalScrollPosition";
private _terminalApplication = _terminal get "AE3_terminalApplication";

if (_terminalApplication == "SHELL") then
{
	if (_scroll >= 0) then
	{
		_terminal set ["AE3_terminalScrollPosition", _terminalScrollPosition + AE3_TerminalScrollSpeed];
	}
	else
	{
		_terminal set ["AE3_terminalScrollPosition", _terminalScrollPosition - AE3_TerminalScrollSpeed];
	};
};

[_computer, _displayorcontrol] call AE3_armaos_fnc_terminal_updateOutput;

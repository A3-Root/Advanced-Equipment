// File: fnc_shell_sshEnd.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Ends an active SSH session on the given (local) computer's terminal: pushes the
 * remote filesystem back to the server, releases the remote mutex and restores the local prompt.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The local computer whose terminal holds the SSH session
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer] call AE3_armaos_fnc_shell_sshEnd;
 *
 * Public: No
 */

params ["_computer"];

private _terminal = _computer getVariable "AE3_terminal";
private _target = _terminal getOrDefault ["AE3_sshTarget", objNull];

if (isNull _target) exitWith {};

// Push the remote filesystem state back to the server
private _fs = _target getVariable ["AE3_filesystem", nil];
if (!isNil "_fs") then
{
	_target setVariable ["AE3_filesystem", _fs, 2];
};

// Clear local session state on the remote object
_target setVariable ["AE3_stdoutRedirect", nil];
_target setVariable ["AE3_terminal", nil];
_target setVariable ["AE3_computer_mutex", objNull, true];

_terminal deleteAt "AE3_sshTarget";

[_computer, localize "STR_AE3_ArmaOS_Ssh_ConnectionClosed"] call AE3_armaos_fnc_shell_stdout;

[_computer] call AE3_armaos_fnc_terminal_updatePromptPointer;

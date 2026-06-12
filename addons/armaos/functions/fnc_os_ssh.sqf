#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Opens an SSH session to another computer over the AE3 network. While the session
 * is active, entered commands are executed against the remote computer's filesystem and the
 * output is shown in the local terminal. End the session with 'exit'. The remote computer is
 * locked (mutex) while the session is active. Interactive programs (games) are blocked.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The local computer object
 * 1: _options <ARRAY> - Command options and arguments: USER@IP PASSWORD
 * 2: _commandName <STRING> - The name of the command
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer, ["admin@192.168.0.5", "secret"], "ssh"] call AE3_armaos_fnc_os_ssh;
 *
 * Public: Yes
 */

params ["_computer", "_options", "_commandName"];

private _commandOpts = [];
private _commandSyntax =
[
	[
			["command", _commandName, true, false],
			["path", "USER@IP", true, false],
			["path", "PASSWORD", true, false]
	]
];
private _commandSettings = [_commandName, _commandOpts, _commandSyntax];

private _ae3OptsSuccess = false; private _ae3OptsThings = [];
[] params ([_computer, _options, _commandSettings] call AE3_armaos_fnc_shell_getOpts);

if (!_ae3OptsSuccess) exitWith {};

private _terminal = _computer getVariable "AE3_terminal";

// Nested SSH sessions are not supported
if (!isNull (_terminal getOrDefault ["AE3_sshTarget", objNull])) exitWith
{
	[_computer, localize "STR_AE3_ArmaOS_Ssh_AlreadyConnected"] call AE3_armaos_fnc_shell_stdout;
};

_ae3OptsThings params ["_userAtIp", "_password"];

private _parts = _userAtIp splitString "@";
if (count _parts != 2) exitWith
{
	[_computer, localize "STR_AE3_ArmaOS_Ssh_Usage"] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};
_parts params ["_user", "_ipString"];

private _targetIp = (_ipString splitString ".") apply { parseNumber _x };
if (count _targetIp != 4) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_InvalidAddress", _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

// Route to the target over the simulated network
([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target", "_routeLength"];

if (isNull _target || {_target isEqualTo _computer}) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_NoRoute", _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

// Target must be an AE3 computer, running and not in use
if (!(_target getVariable ["AE3_cap_hasTerminal", false])) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_ConnectionRefused", _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

if ((_target getVariable ["AE3_power_powerState", 0]) != 1) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_NoRoute", _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

if (!isNull (_target getVariable ["AE3_computer_mutex", objNull])) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_TargetBusy", _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

// Validate credentials against the remote user list (root login over ssh follows the same
// rule as local login: blocked unless AE3_AllowRootLogin is enabled)
[_target, "AE3_Userlist"] call AE3_main_fnc_getRemoteVar;
private _users = _target getVariable ["AE3_Userlist", createHashMap];

private _rootBlocked = (_user isEqualTo "root") && {!(missionNamespace getVariable ["AE3_AllowRootLogin", false])};

if (_rootBlocked || {!(_user in _users)} || {(_users get _user) isNotEqualTo _password}) exitWith
{
	[_computer, format [localize "STR_AE3_ArmaOS_Ssh_AuthFailed", _user, _ipString]] call AE3_armaos_fnc_shell_stdout;
	[_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

// Claim the remote computer (same lock as physical terminal access)
_target setVariable ["AE3_computer_mutex", _computer getVariable ["AE3_computer_mutex", objNull], true];

// Pull the remote filesystem and set up a minimal local session context on the target
[_target, "AE3_filesystem"] call AE3_main_fnc_getRemoteVar;

private _targetTerminal = createHashMap;
_targetTerminal set ["AE3_terminalLoginUser", _user];
_target setVariable ["AE3_terminal", _targetTerminal];
_target setVariable ["AE3_filepointer", [_user] call AE3_armaos_fnc_shell_getHomeDir];

// Redirect all remote stdout into the local terminal
_target setVariable ["AE3_stdoutRedirect", _computer];

_terminal set ["AE3_sshTarget", _target];

[_target, "System", format [localize "STR_AE3_ArmaOS_Exception_UserLoginSuccessful", _user] + " (ssh)", "/var/log/auth.log"] call AE3_armaos_fnc_shell_writeToLogfile;

[_computer, format [localize "STR_AE3_ArmaOS_Ssh_Connected", _user, _ipString]] call AE3_armaos_fnc_shell_stdout;

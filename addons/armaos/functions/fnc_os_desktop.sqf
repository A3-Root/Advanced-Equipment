// File: fnc_os_desktop.sqf
/*
 * Author: Root
 * Description: Switches this laptop from the CLI terminal to the GUI desktop. Closes the terminal
 * dialog and opens the web desktop (holding the laptop mutex). Gated by the same interface-access
 * model as the ACE "Use Desktop" action; when GUI access is denied - or the desktop addon is not
 * loaded - the command reports an error and stays in the terminal. Similar in spirit to a
 * display-manager switch.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object
 * 1: _options <ARRAY> - Command options and arguments
 * 2: _commandName <STRING> - The name of the command
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer, [], "desktop"] call AE3_armaos_fnc_os_desktop;
 *
 * Public: Yes
 */

params ["_computer", "_options", "_commandName"];

private _commandOpts = [];
private _commandSyntax =
[
    [
        ["command", _commandName, true, false]
    ]
];
private _commandSettings = [_commandName, _commandOpts, _commandSyntax];

private _ae3OptsSuccess = false;
[] params ([_computer, _options, _commandSettings] call AE3_armaos_fnc_shell_getOpts);

if (!_ae3OptsSuccess) exitWith {};

private _openWeb = missionNamespace getVariable ["AE3_desktop_fnc_desktop_openWeb", nil];
if (isNil "_openWeb") exitWith
{
    [_computer, ["The desktop interface is not available on this device."]] call AE3_armaos_fnc_shell_stdout;
    [_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

private _canFn = missionNamespace getVariable ["AE3_desktop_fnc_canAccessInterface", nil];
if (!isNil "_canFn" && {!([_computer, player, "gui"] call _canFn)}) exitWith
{
    [_computer, ["Access to the desktop interface is denied on this device."]] call AE3_armaos_fnc_shell_stdout;
    [_computer] call AE3_armaos_fnc_shell_playErrorSound;
};

// Hand the laptop from the CLI to the GUI: keep it claimed for this player, close the terminal, then
// open the web desktop next frame (openWeb re-claims the mutex and shows the "in use" screen).
_computer setVariable ["AE3_computer_mutex", player, true];
closeDialog 1;
[{ params ["_computer", "_openWeb"]; [_computer] spawn _openWeb; }, [_computer, _openWeb]] call CBA_fnc_execNextFrame;

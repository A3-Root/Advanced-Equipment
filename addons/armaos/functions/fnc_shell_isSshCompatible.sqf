// File: fnc_shell_isSshCompatible.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Checks whether a command may be executed over an SSH session. Commands can opt
 * out with "sshCompatible = 0;" in their CfgOsFunctions/CfgGames/CfgSecurityCommands entry
 * (interactive/graphical programs like games). Unknown commands are allowed.
 *
 * Arguments:
 * 0: _commandName <STRING> - Command name as typed (before link resolution)
 *
 * Return Value:
 * Whether the command is allowed over ssh <BOOL>
 *
 * Example:
 * ["snake"] call AE3_armaos_fnc_shell_isSshCompatible; // false
 *
 * Public: No
 */

params ["_commandName"];

private _cfg = configFile >> "CfgOsFunctions" >> _commandName;
if (!isClass _cfg) then { _cfg = configFile >> "CfgGames" >> _commandName; };
if (!isClass _cfg) then { _cfg = configFile >> "CfgSecurityCommands" >> _commandName; };

if (!isClass _cfg) exitWith { true };
if (isNumber (_cfg >> "sshCompatible")) exitWith { (getNumber (_cfg >> "sshCompatible")) == 1 };

true

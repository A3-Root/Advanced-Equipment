// File: fnc_computer_getSudoers.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Reads the accounts listed in a computer's /etc/sudoers file (one username per line).
 * Blank lines and surrounding whitespace are ignored. Returns an empty array when the computer has no
 * filesystem or no sudoers file yet. root is not part of the list; it is always a superuser.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object to read from
 *
 * Return Value:
 * Usernames with superuser rights <ARRAY of STRING>
 *
 * Example:
 * private _sudoers = [_laptop] call AE3_armaos_fnc_computer_getSudoers;
 *
 * Public: Yes
 */

params [["_computer", objNull, [objNull]]];

if (isNull _computer) exitWith { [] };

private _filesystem = _computer getVariable ["AE3_filesystem", []];
if (_filesystem isEqualTo []) exitWith { [] };

private _sudoers = [];

try
{
	// read as root: /etc/sudoers is deliberately unreadable for everyone else
	private _content = [[], _filesystem, "/etc/sudoers", "root", 0] call AE3_filesystem_fnc_getFile;

	if (_content isEqualType "") then
	{
		_sudoers = (_content splitString endl) apply { trim _x };
		_sudoers = _sudoers select { _x isNotEqualTo "" };
	};
}
catch
{
	// no sudoers file (or no /etc at all) means nobody but root is elevated
	_sudoers = [];
};

_sudoers

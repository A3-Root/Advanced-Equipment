#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Creates a password-protected file on laptops (server-side; routed from
 * clients). Players open it with the 'unlock' CLI command or a password prompt in the GUI
 * Files app. The protected payload may itself be a media marker (locked image/video/audio).
 *
 * Arguments:
 * 0: _target <OBJECT|STRING> - Target laptop, its netId, or "all"
 * 1: _path <STRING> - Virtual filesystem path
 * 2: _password <STRING> - Password (any character allowed)
 * 3: _content <STRING> - Protected content (use endl for line breaks)
 * 4: _owner <STRING> (Optional, default: "root") - File owner
 * 5: _permissions <ARRAY> (Optional) - File permissions
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "/home/user/codes.txt", "hunter2", "Launch code: 7741"] call AE3_desktop_fnc_addLockedFile;
 *
 * Public: Yes
 */

params ["_target", "_path", "_password", "_content", ["_owner", "root"], ["_permissions", [[true, true, false], [true, false, false]]]];

if (!isServer) exitWith
{
	private _targetId = if (_target isEqualType objNull) then { netId _target } else { _target };
	["ae3_desktop_addLockedFile", [_targetId, _path, _password, _content, _owner, _permissions]] call CBA_fnc_serverEvent;
};

private _computers = [];
switch (true) do
{
	case (_target isEqualType objNull): { _computers = [_target]; };
	case (_target isEqualTo "all"):     { _computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]); };
	default                             { _computers = [objectFromNetId _target]; };
};

// Length-prefixed so the password may contain any character (incl. '|'); see fnc_shell_parseLockedFile.
private _locked = format ["AE3_LOCKED|%1|%2%3", count _password, _password, _content];

{
	if (!isNull _x && {_x getVariable ["AE3_cap_hasFilesystem", false]}) then
	{
		private _filesystem = _x getVariable ["AE3_filesystem", nil];
		if (!isNil "_filesystem") then
		{
			try
			{
				[[], _filesystem, _path, _locked, _owner, "root", _permissions] call AE3_filesystem_fnc_ensureFile;
					// Publish the updated filesystem so a laptop currently in use sees the new file.
					_x setVariable ["AE3_filesystem", _filesystem, [_x] call AE3_armaos_fnc_computer_getLocality];
			}
			catch
			{
				WARNING_1("Could not create locked file: %1",_exception);
			};
		};
	};
} forEach _computers;

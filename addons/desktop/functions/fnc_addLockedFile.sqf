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
 * 2: _password <STRING> - Password (must not contain "|")
 * 3: _content <STRING> - Protected content (use endl for line breaks)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "/home/user/codes.txt", "hunter2", "Launch code: 7741"] call AE3_desktop_fnc_addLockedFile;
 *
 * Public: Yes
 */

params ["_target", "_path", "_password", "_content"];

if ((_password find "|") >= 0) exitWith
{
	WARNING_1("Locked file password for %1 may not contain '|'",_path);
};

if (!isServer) exitWith
{
	private _targetId = if (_target isEqualType objNull) then { netId _target } else { _target };
	["ae3_desktop_addLockedFile", [_targetId, _path, _password, _content]] call CBA_fnc_serverEvent;
};

private _computers = [];
switch (true) do
{
	case (_target isEqualType objNull): { _computers = [_target]; };
	case (_target isEqualTo "all"):     { _computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]); };
	default                             { _computers = [objectFromNetId _target]; };
};

private _locked = format ["AE3_LOCKED|%1|%2", _password, _content];

{
	if (!isNull _x && {_x getVariable ["AE3_cap_hasFilesystem", false]}) then
	{
		private _filesystem = _x getVariable ["AE3_filesystem", nil];
		if (!isNil "_filesystem") then
		{
			try
			{
				[[], _filesystem, _path, _locked, "root", "root", [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
			}
			catch
			{
				WARNING_1("Could not create locked file: %1",_exception);
			};
		};
	};
} forEach _computers;

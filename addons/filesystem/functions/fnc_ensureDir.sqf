#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Creates a directory if it does not already exist. Idempotent wrapper around createDir: the "already exists" exception is swallowed, any other exception is rethrown.
 *
 * Arguments:
 * 0: _pntr <ARRAY> - Current directory pointer
 * 1: _filesystem <ARRAY> - Filesystem object
 * 2: _target <STRING> - Path to directory
 * 3: _user <STRING> - User creating the directory
 * 4: _owner <STRING> (Optional, default: _user) - Owner of the new directory
 * 5: _permissions <ARRAY> (Optional, default: [[true,true,true],[false,false,false]]) - Permissions [[owner r,w,x],[everyone r,w,x]]
 *
 * Return Value:
 * true if the directory was created, false if it already existed <BOOL>
 *
 * Example:
 * [[], _filesystem, "/mnt/USB1", "root"] call AE3_filesystem_fnc_ensureDir;
 *
 * Public: Yes
 */

params['_pntr', '_filesystem', '_target', '_user', '_owner', ['_permissions', [[true, true, true], [false, false, false]]]];

private _created = true;

try
{
	[_pntr, _filesystem, _target, _user, _owner, _permissions] call AE3_filesystem_fnc_createDir;
}
catch
{
	private _normalizedException = _exception regexReplace ["'(.+)'", "'%1'"];
	if (_normalizedException isEqualTo (localize "STR_AE3_Filesystem_Exception_AlreadyExists")) then
	{
		INFO_1("Directory already exists, skipping: %1",_exception);
		_created = false;
	}
	else
	{
		throw _exception;
	};
};

_created

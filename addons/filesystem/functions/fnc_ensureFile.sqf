#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Creates a file if it does not already exist. Idempotent wrapper around createFile: the "already exists" exception is swallowed, any other exception is rethrown.
 *
 * Arguments:
 * 0: _pntr <ARRAY> - Current directory pointer
 * 1: _filesystem <ARRAY> - Filesystem object
 * 2: _target <STRING> - Path to file
 * 3: _content <STRING|CODE> - File content
 * 4: _user <STRING> - User creating the file
 * 5: _owner <STRING> (Optional, default: _user) - Owner of the new file
 * 6: _permissions <ARRAY> (Optional, default: [[true,true,false],[false,false,false]]) - Permissions [[owner r,w,x],[everyone r,w,x]]
 *
 * Return Value:
 * true if the file was created, false if it already existed <BOOL>
 *
 * Example:
 * [[], _filesystem, "/var/mail/inbox", "", "root"] call AE3_filesystem_fnc_ensureFile;
 *
 * Public: Yes
 */

params['_pntr', '_filesystem', '_target', '_content', '_user', '_owner', ['_permissions', [[true, true, false], [false, false, false]]]];

private _created = true;

try
{
	[_pntr, _filesystem, _target, _content, _user, _owner, _permissions] call AE3_filesystem_fnc_createFile;
}
catch
{
	private _normalizedException = _exception regexReplace ["'(.+)'", "'%1'"];
	if (_normalizedException isEqualTo (localize "STR_AE3_Filesystem_Exception_AlreadyExists")) then
	{
		// Idempotent by design: an existing file is the expected no-op, not worth logging.
		_created = false;
	}
	else
	{
		throw _exception;
	};
};

_created

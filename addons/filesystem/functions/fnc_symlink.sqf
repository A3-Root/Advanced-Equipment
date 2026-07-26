// File: fnc_symlink.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Creates a symbolic link at the given path that points to an absolute target path. The
 * link is stored as an ordinary file whose content is AE3_SYMLINK_PREFIX + target, so it rides
 * through the standard filesystem functions and the network sync unchanged. Link following is done
 * by the consumers (fsHandle read/copy, GUI navigation) via AE3_filesystem_fnc_symlinkTarget.
 *
 * Arguments:
 * 0: _pntr <ARRAY> - Current directory pointer
 * 1: _filesystem <ARRAY> - Filesystem object
 * 2: _linkPath <STRING> - Path of the link to create
 * 3: _target <STRING> - Absolute path the link points to
 * 4: _user <STRING> - User creating the link
 * 5: _owner <STRING> (Optional, default: _user) - Owner of the link
 * 6: _permissions <ARRAY> (Optional, default: rwx owner / r-x others) - Permissions
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], _fs, "/home/admin/Desktop/crack.app", "/usr/share/applications/crack.app", "admin"] call AE3_filesystem_fnc_symlink;
 *
 * Public: Yes
 */

params ["_pntr", "_filesystem", "_linkPath", "_target", "_user", ["_owner", nil], ["_permissions", [[true, true, true], [true, false, true]]]];

if (isNil "_owner") then { _owner = _user; };

private _content = AE3_SYMLINK_PREFIX + _target;
[_pntr, _filesystem, _linkPath, _content, _user, _owner, _permissions] call AE3_filesystem_fnc_createFile;

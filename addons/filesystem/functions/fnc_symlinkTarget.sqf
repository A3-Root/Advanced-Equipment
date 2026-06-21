#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Inspects a filesystem object's content and, if it is a symbolic link, returns the
 * absolute target path. Non-link content (directories, plain files, code) returns "". Used to follow
 * links transparently in fsHandle (read/copy) and to expose link targets to the web desktop.
 *
 * Arguments:
 * 0: _content <ANY> - The content slot of a filesystem object ((_object select 0))
 *
 * Return Value:
 * Absolute target path, or "" if the content is not a symlink <STRING>
 *
 * Example:
 * private _t = [(_obj select 0)] call AE3_filesystem_fnc_symlinkTarget;
 *
 * Public: Yes
 */

params ["_content"];

if (!(_content isEqualType "")) exitWith { "" };

private _plen = count AE3_SYMLINK_PREFIX;
if (_content select [0, _plen] isEqualTo AE3_SYMLINK_PREFIX) exitWith {
    _content select [_plen]
};

"";

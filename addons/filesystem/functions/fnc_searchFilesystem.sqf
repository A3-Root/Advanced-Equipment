// File: fnc_searchFilesystem.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Recursively searches the filesystem for files and directories whose name matches a
 * case-insensitive glob pattern ("*" wildcard). Respects read permissions: subtrees the user cannot
 * read are skipped. Returns absolute paths plus a directory flag for each hit. Used by the web
 * desktop's Files / My Computer search box and the global search bar.
 *
 * Arguments:
 * 0: _pointer <ARRAY> - Current directory pointer (start [] for root)
 * 1: _filesystem <ARRAY> - Filesystem object (the subtree rooted at _pointer)
 * 2: _user <STRING> - User performing the search
 * 3: _regex <STRING> - Pre-built, lowercased regex (translated from the user glob)
 * 4: _results <ARRAY> (Optional, default: []) - Accumulator
 *
 * Return Value:
 * Array of [absolutePath, isDir] entries <ARRAY>
 *
 * Example:
 * [[], _fs, "user", "report.*"] call AE3_filesystem_fnc_searchFilesystem;
 *
 * Public: No
 */

params ["_pointer", "_filesystem", "_user", "_regex", ["_results", []]];

private _content = _filesystem select 0;

try {
    [_filesystem, _user, 0] call AE3_filesystem_fnc_hasPermission;

    {
        private _isDir = (_y select 0) isEqualType createHashMap;
        if (toLower _x regexMatch _regex) then {
            private _path = "/" + (_pointer joinString "/");
            if (_path isNotEqualTo "/") then { _path = _path + "/"; };
            _results pushBack [_path + _x, _isDir];
        };
        if (_isDir) then {
            private _childPointer = +_pointer;
            _childPointer pushBack _x;
            [_childPointer, _y, _user, _regex, _results] call AE3_filesystem_fnc_searchFilesystem;
        };
    } forEach _content;
} catch {};

_results;

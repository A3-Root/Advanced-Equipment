#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Filesystem operations for the web desktop Files/Notepad apps (WS-C/D). Operates on
 * the laptop's locally-cached AE3_filesystem copy (pulled via getRemoteVar in
 * AE3_desktop_fnc_desktop_openWeb), reusing the standard AE3 filesystem functions so Unix
 * permissions are enforced exactly like the CLI. Per-user scoping (#9): root and admin act as
 * "root" and bypass permission checks; every other user is bound by ownership/permission bits.
 * Mutating ops (save/mkdir/delete) push the updated filesystem back to the server.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 * 1: _user <STRING> - The logged-in session user
 * 2: _op <STRING> - "list" | "read" | "save" | "mkdir" | "delete"
 * 3: _data <HASHMAP> - Operation data (keys: "path", "content")
 *
 * Return Value:
 * Result <HASHMAP> - op-specific; always carries "error" ("" on success)
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]], ["_user", "", [""]], ["_op", "", [""]], ["_data", createHashMap, [createHashMap]]];

private _res = createHashMapFromArray [["error", ""]];

if (isNull _computer) exitWith { _res set ["error", "no_device"]; _res };

private _fs = _computer getVariable ["AE3_filesystem", []];
if (_fs isEqualTo []) exitWith { _res set ["error", "fs_not_ready"]; _res };

// #9: root and admin see/modify everything; everyone else is permission-bound.
private _fsUser = [_user, "root"] select (_user in ["root", "admin"]);
private _path = _data getOrDefault ["path", "/"];

switch (_op) do {

    case "list": {
        private _entries = [];
        try {
            ([[], _fs, _path, _fsUser] call AE3_filesystem_fnc_chdir) params ["", "_dir"];
            [_dir, _fsUser, 0] call AE3_filesystem_fnc_hasPermission;
            private _content = _dir select 0;
            private _names = keys _content;
            _names sort true;
            {
                private _child = _content get _x;
                _entries pushBack createHashMapFromArray [
                    ["name", _x],
                    ["dir", (_child select 0) isEqualType createHashMap]
                ];
            } forEach _names;
            _res set ["entries", _entries];
        } catch {
            _res set ["error", "denied"];
            _res set ["entries", []];
        };
    };

    case "read": {
        try {
            private _content = [[], _fs, _path, _fsUser, 0] call AE3_filesystem_fnc_getFile;
            if (_content isEqualType "") then { _res set ["content", _content]; }
            else { _res set ["error", "not_text"]; };
        } catch {
            _res set ["error", "denied"];
        };
    };

    case "save": {
        private _content = _data getOrDefault ["content", ""];
        try {
            [[], _fs, _path, "", _fsUser, _user, [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
            [[], _fs, _path, _fsUser, _content, false] call AE3_filesystem_fnc_writeToFile;
            _computer setVariable ["AE3_filesystem", _fs, 2];
            _res set ["ok", true];
        } catch {
            _res set ["error", "denied"];
        };
    };

    case "mkdir": {
        try {
            [[], _fs, _path, _fsUser, _user] call AE3_filesystem_fnc_ensureDir;
            _computer setVariable ["AE3_filesystem", _fs, 2];
            _res set ["ok", true];
        } catch {
            _res set ["error", "denied"];
        };
    };

    case "delete": {
        try {
            [[], _fs, _path, _fsUser] call AE3_filesystem_fnc_delObj;
            _computer setVariable ["AE3_filesystem", _fs, 2];
            _res set ["ok", true];
        } catch {
            _res set ["error", "denied"];
        };
    };

    default { _res set ["error", "bad_op"]; };
};

_res

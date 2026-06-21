#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side SSH backend for the web SSH app (#19). Handles connect (auth against the
 * REMOTE device's user list + its SSH-enabled flag) and remote filesystem ops (list/read) plus
 * cross-device copy (pull remote->local, push local->remote). Every op replies to the requesting
 * client via "ae3_desktop_sshReply", echoing the rid so the JS A3.request promise resolves.
 * Server-only.
 *
 * Arguments:
 * 0: _clientOwner <NUMBER> - clientOwner that issued the request
 * 1: _rid <STRING> - request id to echo back
 * 2: _localNetId <STRING> - netId of the laptop running the SSH client
 * 3: _targetNetId <STRING> - netId of the remote device
 * 4: _user <STRING> - remote username
 * 5: _pass <STRING> - remote password
 * 6: _op <STRING> - "connect" | "ls" | "read" | "pull" | "push"
 * 7: _data <HASHMAP> - op-specific (path, dest, content)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_clientOwner", "_rid", "_localNetId", "_targetNetId", "_user", "_pass", "_op", ["_data", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};

private _reply = {
    params ["_cmd", "_payload"];
    ["ae3_desktop_sshReply", [_clientOwner, _rid, _cmd, _payload]] call CBA_fnc_ownerEvent;
};

private _target = objectFromNetId _targetNetId;
private _res = createHashMapFromArray [["error", ""]];

if (isNull _target) exitWith { _res set ["error", "no_route"]; ["ssh_" + _op, _res] call _reply; };

// SSH must be enabled on the remote device (#19).
if !(_target getVariable ["AE3_ssh_enabled", false]) exitWith {
    _res set ["error", "ssh_disabled"]; ["ssh_" + _op, _res] call _reply;
};

// Authenticate against the remote user list.
private _authed = ([_target, _user, _pass] call AE3_desktop_fnc_authUser) getOrDefault ["ok", false];
if (!_authed) exitWith { _res set ["error", "auth_failed"]; ["ssh_" + _op, _res] call _reply; };

private _fsUser = ["root", _user] select (!(_user in ["root", "admin"]));
private _tfs = _target getVariable ["AE3_filesystem", []];

switch (_op) do {

    case "connect": {
        _res set ["ok", true];
        _res set ["host", _target getVariable ["ace_cargo_customName", "remote"]];
    };

    case "ls": {
        private _path = _data getOrDefault ["path", "/"];
        private _entries = [];
        try {
            ([[], _tfs, _path, _fsUser] call AE3_filesystem_fnc_chdir) params ["", "_dir"];
            [_dir, _fsUser, 0] call AE3_filesystem_fnc_hasPermission;
            private _content = _dir select 0;
            private _names = keys _content; _names sort true;
            {
                private _child = _content get _x;
                private _link = [(_child select 0)] call AE3_filesystem_fnc_symlinkTarget;
                _entries pushBack createHashMapFromArray [
                    ["name", _x], ["dir", (_child select 0) isEqualType createHashMap], ["link", _link]
                ];
            } forEach _names;
            _res set ["entries", _entries];
        } catch { _res set ["error", "denied"]; _res set ["entries", []]; };
    };

    case "read": {
        private _path = _data getOrDefault ["path", ""];
        try {
            private _content = [[], _tfs, _path, _fsUser, 0] call AE3_filesystem_fnc_getFile;
            if (_content isEqualType "") then { _res set ["content", _content]; } else { _res set ["error", "not_text"]; };
        } catch { _res set ["error", "denied"]; };
    };

    // Copy a remote file down to the local laptop.
    case "pull": {
        private _src = _data getOrDefault ["path", ""];
        private _dest = _data getOrDefault ["dest", ""];
        private _local = objectFromNetId _localNetId;
        try {
            private _content = [[], _tfs, _src, _fsUser, 0] call AE3_filesystem_fnc_getFile;
            private _lfs = _local getVariable ["AE3_filesystem", []];
            [[], _lfs, _dest, "", "root", "root", [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
            [[], _lfs, _dest, "root", _content, false] call AE3_filesystem_fnc_writeToFile;
            _local setVariable ["AE3_filesystem", _lfs, 2];
            _res set ["ok", true];
        } catch { _res set ["error", "denied"]; };
    };

    // Copy a local file up to the remote device.
    case "push": {
        private _src = _data getOrDefault ["path", ""];
        private _dest = _data getOrDefault ["dest", ""];
        private _local = objectFromNetId _localNetId;
        try {
            private _lfs = _local getVariable ["AE3_filesystem", []];
            private _content = [[], _lfs, _src, "root", 0] call AE3_filesystem_fnc_getFile;
            [[], _tfs, _dest, "", _fsUser, _fsUser, [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
            [[], _tfs, _dest, _fsUser, _content, false] call AE3_filesystem_fnc_writeToFile;
            _target setVariable ["AE3_filesystem", _tfs, 2];
            _res set ["ok", true];
        } catch { _res set ["error", "denied"]; };
    };

    default { _res set ["error", "bad_op"]; };
};

["ssh_" + _op, _res] call _reply;

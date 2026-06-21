#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side fetch of a laptop's IM threads (/var/chat/<peerIP>) for the web Messenger
 * app. Reads the authoritative filesystem so incoming messages appear live, parses each thread into
 * structured {dir,time,text} messages, then pushes the per-peer threads back to the requesting
 * client (which forwards them to the browser). Server-only. (AE3 GUI issue #7)
 *
 * Arguments:
 * 0: _owner <NUMBER> - clientOwner that requested the pull
 * 1: _computerNetId <STRING> - netId of the laptop
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_owner", -1, [0]], ["_computerNetId", "", [""]]];

if (!isServer) exitWith {};

private _computer = objectFromNetId _computerNetId;
if (isNull _computer) exitWith {};

// Threads: array of [peerIp, [[dir,time,text], ...]] ordered by peer.
private _threads = [];
private _fs = _computer getVariable ["AE3_filesystem", []];
if (_fs isNotEqualTo []) then {
    try {
        ([[], _fs, "/var/chat", "root"] call AE3_filesystem_fnc_chdir) params ["", "_dir"];
        private _content = _dir select 0;
        private _peers = keys _content;
        _peers sort true;
        {
            private _entry = _content get _x;
            if ((_entry select 0) isEqualType "") then {
                private _msgs = [];
                {
                    if (_x isNotEqualTo "") then {
                        // "<dir>|HH:MM|<text>" with fixed offsets (see ae3_network_imSend).
                        _msgs pushBack [_x select [0, 1], _x select [2, 5], _x select [8]];
                    };
                } forEach ((_entry select 0) splitString endl);
                _threads pushBack [_x, _msgs];
            };
        } forEach _peers;
    } catch {};
};

["ae3_desktop_chatData", [_threads], _owner] call CBA_fnc_ownerEvent;

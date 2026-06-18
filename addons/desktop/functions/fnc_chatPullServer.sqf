#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side fetch of a laptop's IM inbox (/var/mail/inbox) for the web Messenger
 * app. Reads the authoritative filesystem so incoming messages appear live, then pushes the text
 * back to the requesting client (which forwards it to the browser). Server-only.
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

private _text = "";
private _fs = _computer getVariable ["AE3_filesystem", []];
if (_fs isNotEqualTo []) then {
    try {
        private _content = [[], _fs, "/var/mail/inbox", "root", 0] call AE3_filesystem_fnc_getFile;
        if (_content isEqualType "") then { _text = _content; };
    } catch {};
};

["ae3_desktop_chatData", [_text], _owner] call CBA_fnc_ownerEvent;

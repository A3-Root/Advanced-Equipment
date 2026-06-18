#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Replies to a web-desktop A3.request from a custom command handler (registered via
 * AE3_desktop_fnc_registerCmd). Echoes the request's _rid so the JS-side Promise resolves. No-op
 * for fire-and-forget commands (empty rid). Client-only.
 *
 * Arguments:
 * 0: _command <STRING> - The command being answered
 * 1: _rid <STRING> - The request id passed to the handler
 * 2: _payload <ANY> - The result data
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [["_command", "", [""]], ["_rid", "", [""]], ["_payload", []]];

if (_rid isEqualTo "") exitWith {};

[_command, createHashMapFromArray [["_rid", _rid], ["data", _payload]]] call FUNC(jsSend);

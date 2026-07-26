// File: fnc_registerCmd.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a handler for a custom web-desktop command, letting other addons extend
 * the JS<->SQF router (AE3_desktop_fnc_jsRouter) without modifying AE3. When the browser sends a
 * command the core router does not know, the router looks it up here and calls the handler with
 * [_computer, _user, _data, _rid]. Handlers that produce an immediate result can reply via
 * AE3_desktop_fnc_jsReply; asynchronous handlers (server round-trips) push results later via
 * AE3_desktop_fnc_jsSend. Call at preInit/postInit.
 *
 * Arguments:
 * 0: _cmd <STRING> - Command name sent from JS
 * 1: _code <CODE> - Handler: params ["_computer", "_user", "_data", "_rid"]
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [["_cmd", "", [""]], ["_code", {}, [{}]]];

if (_cmd isEqualTo "") exitWith {};

private _handlers = missionNamespace getVariable [QGVAR(cmdHandlers), createHashMap];
_handlers set [_cmd, _code];
missionNamespace setVariable [QGVAR(cmdHandlers), _handlers];

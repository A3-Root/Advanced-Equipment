/*
 * Author: Root
 * Description: Logs an AE3 network event (remoteExec / CBA event) to the RPT via diag_log when
 * network debug is enabled (toggled by AE3_main_fnc_manageNetworkDebug). Call this at AE3 network
 * call sites instead of relying on a (non-existent) remoteExec mission event handler.
 *
 * Arguments:
 * 0: _direction <STRING> - "send" or "recv"
 * 1: _name <STRING> - Function / event name
 * 2: _target <ANY> (Optional, default: "") - remoteExec target / recipients
 * 3: _args <ANY> (Optional, default: []) - Payload
 *
 * Return Value:
 * None
 *
 * Example:
 * ["send", "AE3_power_fnc_turnOnDevice", 2, [_device]] call AE3_main_fnc_netLog;
 *
 * Public: No
 */

if !(missionNamespace getVariable ["AE3_NetworkDebugEnabled", false]) exitWith {};

params [["_direction", "send"], ["_name", ""], ["_target", ""], ["_args", []]];

diag_log format ["[AE3][NET][%1] fn=%2 target=%3 args=%4", _direction, _name, _target, _args];

// File: fnc_manageNetworkDebug.sqf
/*
 * Author: Root
 * Description: Toggles AE3 network debug logging. Sets the AE3_NetworkDebugEnabled flag that
 * AE3_main_fnc_netLog checks before writing remoteExec/CBA-event traffic to the RPT via diag_log.
 *
 * Note: Arma has no mission event handler that receives remoteExec calls (there is no
 * "HandleRemoteExec" enum - see reference_files/MISSION_EVENT_HANDLER.md). Logging is therefore
 * done at AE3's own network call sites via AE3_main_fnc_netLog, gated on this flag.
 *
 * Arguments:
 * 0: _enabled <BOOL> - Enable/disable logging
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call AE3_main_fnc_manageNetworkDebug;
 *
 * Public: No
 */

params ["_enabled"];

missionNamespace setVariable ["AE3_NetworkDebugEnabled", _enabled];

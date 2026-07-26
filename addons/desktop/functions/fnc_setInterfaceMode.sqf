// File: fnc_setInterfaceMode.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Sets the interface mode of a laptop: "cli" (classic terminal only), "gui"
 * (desktop only) or "both" (two ACE actions; combine with AE3_desktop_fnc_setInterfaceAccess
 * to decide who may use which). Mission-maker / framework API - players cannot switch modes.
 * Routed to the server from clients; the mode is stored as a public object variable.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 * 1: _mode <STRING> - "cli", "gui" or "both"
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "gui"] call AE3_desktop_fnc_setInterfaceMode;
 *
 * Public: Yes
 */

params ["_computer", "_mode"];

if (isNull _computer) exitWith {};
if (!(_mode in ["cli", "gui", "both"])) exitWith {};

if (!isServer) exitWith
{
	["ae3_desktop_setInterfaceMode", [_computer, _mode]] call CBA_fnc_serverEvent;
};

_computer setVariable ["AE3_interfaceMode", _mode, true];

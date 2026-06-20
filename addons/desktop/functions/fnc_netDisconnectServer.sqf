#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side wireless disconnect for the web Network app (#11). Drops the laptop from
 * its current router using the authoritative AE3 network function (which broadcasts the cleared
 * parent/address). Mirrors AE3_desktop_fnc_netConnectServer. Server-only, no-op when not connected.
 *
 * Arguments:
 * 0: _device <OBJECT> - The laptop
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_device", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _device) exitWith {};

if (!isNull (_device getVariable ["AE3_network_parent", objNull])) then {
    [_device] call AE3_network_fnc_disconnect;
};

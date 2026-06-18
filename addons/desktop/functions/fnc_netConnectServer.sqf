#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side wireless (re)connect for the web Network app (#11). Disconnects the
 * laptop from its current router (if any) then connects it to the requested router, reusing the
 * authoritative AE3 network functions (which broadcast the new parent/address). Server-only.
 *
 * Arguments:
 * 0: _device <OBJECT> - The laptop
 * 1: _router <OBJECT> - Target router
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_device", objNull, [objNull]], ["_router", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _device || isNull _router) exitWith {};

if (!isNull (_device getVariable ["AE3_network_parent", objNull])) then {
    [_device] call AE3_network_fnc_disconnect;
};

[_device, _router] call AE3_network_fnc_connect_device2router;

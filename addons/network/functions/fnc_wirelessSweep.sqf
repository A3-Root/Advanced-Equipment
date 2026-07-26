// File: fnc_wirelessSweep.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Keeps every wireless connection honest for as long as it lasts. A laptop joins a network
 * by standing inside a router's range and giving its password, but nothing held it there afterwards: the
 * connection was made once and then kept regardless of where either end went, so a laptop carried to the
 * far side of the map stayed on the network it left behind and remained reachable over it. A router that
 * is carried - an EWO's backpack - moves the range itself, which makes the check a live one rather than
 * something that can be settled at connect time.
 *
 * Each pass drops the clients that no longer have a network to be on: those out of their router's
 * wireless range, and those whose router is dead or switched off. A dropped client loses its address and
 * has to come back into range and connect again, so it can no longer be reached from anywhere.
 *
 * Cascaded child routers are left alone: they manage their own subnets and a mission may deliberately
 * link two routers that stand far apart.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!isServer) exitWith {};

{
    private _router = _x;
    if (isNull _router) then {continue};

    private _routerDown = !alive _router || {(_router getVariable ["AE3_power_powerState", 1]) != 1};
    private _range = _router getVariable ["AE3_network_wirelessRange", 100];

    // Copied before iterating: removeNetworkConnection edits the children array as it goes.
    {
        private _client = _x;
        if (isNull _client || {_client getVariable ["AE3_cap_isRouter", false]}) then {continue};

        if (_routerDown || {(_client distance _router) > _range}) then {
            private _clientOwner = owner _client;
            if (_clientOwner > 0) then {
                ["ae3_desktop_netResult", [false, ["Out of range", "Router offline"] select _routerDown], _clientOwner] call CBA_fnc_ownerEvent;
            };
            [_client] call AE3_network_fnc_removeNetworkConnection;
        };
    } forEach (+(_router getVariable ["AE3_network_children", []]));
} forEach (missionNamespace getVariable ["AE3_network_routers", []]);

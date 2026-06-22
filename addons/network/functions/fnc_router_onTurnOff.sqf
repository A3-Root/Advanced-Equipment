#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles turning off a router: resets the IP address of every connected network
 * consumer (client) to 127.0.0.1. Connected routers keep their own addressing (they manage their
 * own subnets). Connections themselves are kept, so DHCP re-assigns addresses when the router is
 * turned back on. Routed to the server from any machine.
 *
 * Arguments:
 * 0: _router <OBJECT> - The router being turned off
 *
 * Return Value:
 * true <BOOL>
 *
 * Example:
 * [_router] call AE3_network_fnc_router_onTurnOff;
 *
 * Public: No
 */

params ["_router"];

if (!isServer) exitWith
{
	["ae3_network_routerOff", [_router]] call CBA_fnc_serverEvent;
	true
};

// Copy before iterating: fnc_removeNetworkConnection modifies the children array
private _children = +(_router getVariable ["AE3_network_children", []]);
{
	// Cascaded routers manage their own subnets; only fully disconnect regular clients
	if (!(_x getVariable ["AE3_cap_isRouter", false])) then
	{
		private _clientOwner = owner _x;
		if (_clientOwner > 0) then
		{
			["ae3_desktop_netResult", [false, "Router offline"], _clientOwner] call CBA_fnc_ownerEvent;
		};
		[_x] call AE3_network_fnc_removeNetworkConnection;
	};
} forEach _children;

true

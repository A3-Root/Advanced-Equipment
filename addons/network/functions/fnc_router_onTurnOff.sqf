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

{
	// Only reset regular clients - never reset the address of a connected router
	if (!(_x getVariable ["AE3_cap_isRouter", false])) then
	{
		_x setVariable ["AE3_network_address", [127, 0, 0, 1], true];
	};
} forEach (_router getVariable ["AE3_network_children", []]);

true

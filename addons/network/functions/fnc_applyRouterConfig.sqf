/*
 * Author: Root
 * Description: Applies wireless configuration to a router and broadcasts it: network name
 * (ace_cargo_customName, used as the SSID by the Network app), wireless range, and password. Shared
 * by the in-browser router admin page (AE3_desktop_fnc_routerHandle), the Eden/Zeus router
 * attributes, and the Configure Router module. Server-only. (#1/#3)
 *
 * Arguments:
 * 0: _router <OBJECT> - The router object
 * 1: _name <STRING> - New network name (blank = leave unchanged)
 * 2: _range <NUMBER> - Wireless range in metres (<= 0 = leave unchanged)
 * 3: _password <STRING> - Network password ("" = open network)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_router, "Cafe Wifi", 80, "latte"] call AE3_network_fnc_applyRouterConfig;
 *
 * Public: Yes
 */

params [["_router", objNull, [objNull]], ["_name", "", [""]], ["_range", 0, [0]], ["_password", "", [""]]];

if (!isServer) exitWith {};
if (isNull _router) exitWith {};

if (_name isNotEqualTo "") then { _router setVariable ["ace_cargo_customName", _name, true]; };
if (_range > 0) then { _router setVariable ["AE3_network_wirelessRange", _range, true]; };
_router setVariable ["AE3_network_password", _password, true];

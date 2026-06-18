#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Lists AE3 routers within wireless range of the laptop for the web Network app (#11).
 * Routers are tagged AE3_cap_isRouter by AE3_network_fnc_initRouter. Returns a lightweight list
 * (ssid + ip + netId) the client uses to render and to request a connection. Client-local read.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 *
 * Return Value:
 * Networks <ARRAY> of <HASHMAP> - keys: ssid, ip, netId, current
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]]];

if (isNull _computer) exitWith { [] };

private _range = missionNamespace getVariable [QGVAR(wirelessRange), 15];
private _parent = _computer getVariable ["AE3_network_parent", objNull];

private _routers = (nearestObjects [_computer, [], _range]) select {
    (_x != _computer) && {alive _x} && {_x getVariable ["AE3_cap_isRouter", false]}
};

private _list = [];
{
    private _ssid = _x getVariable ["ace_cargo_customName", ""];
    if (_ssid isEqualTo "") then { _ssid = getText (configOf _x >> "displayName"); };
    if (_ssid isEqualTo "") then { _ssid = typeOf _x; };
    _list pushBack createHashMapFromArray [
        ["ssid", _ssid],
        ["ip", ([_x getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str)],
        ["netId", netId _x],
        ["current", _x isEqualTo _parent]
    ];
} forEach _routers;

_list

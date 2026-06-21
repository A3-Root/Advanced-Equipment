#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Lists AE3 routers within wireless range of the laptop for the web Network app.
 * Routers are tagged AE3_cap_isRouter by AE3_network_fnc_initRouter. Returns a lightweight list
 * (ssid + ip + netId) the client uses to render and to request a connection. Client-local read.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 *
 * Return Value:
 * Networks <ARRAY> of <HASHMAP> - keys: ssid, ip, netId, current, locked
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]]];

if (isNull _computer) exitWith { [] };

// Each router advertises its OWN wireless range: a laptop sees a network only when it sits
// within that router's range, not a single global radius. Scan out to the configured maximum, then
// keep routers whose individual range reaches this laptop.
private _scanCap = missionNamespace getVariable [QGVAR(wirelessRangeMax), 500];
private _parent = _computer getVariable ["AE3_network_parent", objNull];

private _routers = (nearestObjects [_computer, [], _scanCap]) select {
    (_x != _computer) && {alive _x} && {_x getVariable ["AE3_cap_isRouter", false]} &&
    {(_computer distance _x) <= (_x getVariable ["AE3_network_wirelessRange", 50])}
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
        ["current", _x isEqualTo _parent],
        ["locked", (_x getVariable ["AE3_network_password", ""]) isNotEqualTo ""]
    ];
} forEach _routers;

_list

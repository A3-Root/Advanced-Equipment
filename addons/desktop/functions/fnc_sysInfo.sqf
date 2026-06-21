#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Collects laptop status (power, battery, network, host, uptime) for the web desktop
 * Settings/System panel (#14). Reuses the same object variables the native System Monitor read.
 * Pure read, client-local.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 *
 * Return Value:
 * Info <HASHMAP> - keys: hostname, ip, gateway, power, battery, uptime
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]]];

private _info = createHashMapFromArray [
    ["hostname", "ae3-os"], ["ip", "-"], ["gateway", "-"], ["power", "-"], ["battery", -1], ["uptime", "-"]
];
if (isNull _computer) exitWith { _info };

private _powerState = _computer getVariable ["AE3_power_powerState", 0];
_info set ["power", (["OFF", "ON", "STANDBY", "CRASHED"] param [_powerState, "UNKNOWN"])];

private _battery = _computer getVariable ["AE3_power_internal", objNull];
if (!isNull _battery) then {
    private _level = _battery getVariable ["AE3_power_batteryLevel", -1];
    private _capacity = _battery getVariable ["AE3_power_batteryCapacity", -1];
    if (_level >= 0 && _capacity > 0) then { _info set ["battery", floor ((_level / _capacity) * 100)]; };
};

_info set ["ip", ([_computer getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str)];

private _gateway = _computer getVariable ["AE3_network_parent", objNull];
if (!isNull _gateway) then {
    _info set ["gateway", ([_gateway getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str)];
};

_info set ["hostname", _computer getVariable ["ace_cargo_customName", "armaOS"]];
_info set ["uptime", ([CBA_missionTime, "HH:MM:SS"] call BIS_fnc_secondsToString)];
// Per-laptop wallpaper (#15): a CSS background string or image path ("" = the theme default).
_info set ["wallpaper", _computer getVariable ["AE3_desktop_wallpaper", ""]];

_info

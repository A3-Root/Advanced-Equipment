#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Sets who may open a given interface (CLI or GUI) on a laptop. Mission-maker /
 * framework API - there is intentionally no player-facing way to change this.
 * The condition is either CODE ([_laptop, _player] -> BOOL) or an ARRAY of player UIDs
 * and/or sides. Routed to the server; stored as a public object variable so it applies on
 * every client and for JIP.
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The laptop
 * 1: _iface <STRING> - "cli" or "gui"
 * 2: _condition <CODE|ARRAY> - Access condition (see above); {true} to reset
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;                  // BLUFOR only
 * [_laptop, "cli", ["76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;  // one player
 * [_laptop, "gui", { (_this select 1) getVariable ["hasKeycard", false] }] call AE3_desktop_fnc_setInterfaceAccess;
 *
 * Public: Yes
 */

params ["_laptop", "_iface", "_condition"];

if (isNull _laptop) exitWith {};
if (!(_iface in ["cli", "gui"])) exitWith {};

if (!isServer) exitWith
{
	["ae3_desktop_setInterfaceAccess", [_laptop, _iface, _condition]] call CBA_fnc_serverEvent;
};

_laptop setVariable [format ["AE3_%1AccessCondition", _iface], _condition, true];

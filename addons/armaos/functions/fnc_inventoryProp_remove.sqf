// File: fnc_inventoryProp_remove.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Removes the world stand-in model created by AE3_armaos_fnc_inventoryProp_spawn when a
 * used-from-inventory session ends (closed, operator dead, or laptop gone). Runs on the server.
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The laptop object the stand-in was stored on
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop] remoteExec ["AE3_armaos_fnc_inventoryProp_remove", 2];
 *
 * Public: No
 */

params ["_laptop"];

if (!isServer) exitWith {};
if (isNull _laptop) exitWith {};

private _prop = _laptop getVariable ["AE3_armaos_invProp", objNull];
if (!isNull _prop) then { detach _prop; deleteVehicle _prop; };

_laptop setVariable ["AE3_armaos_invProp", objNull, true];

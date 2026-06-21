#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Module function for "Configure Router (Wireless)" (#14). Applies the wireless range
 * and password set in the module attributes to every synced router, broadcasting the values so the
 * web Network app's scan/connect (AE3_network_fnc_netScan / AE3_desktop_fnc_netConnectServer) enforce
 * them. Server-only. Works from the Eden editor and Zeus (synced module).
 *
 * Arguments:
 * 0: _module <OBJECT> - The module object
 * 1: _syncedUnits <ARRAY> - Synced entities (expected: routers)
 * 2: _activated <BOOL> - Activation state
 *
 * Return Value:
 * Success <BOOL>
 *
 * Public: No
 */

params ["_module", "_syncedUnits", "_activated"];

if (!_activated) exitWith { true };
if (!isServer) exitWith {};

private _range = _module getVariable ["AE3_ModuleRouter_Range", 50];
if !(_range isEqualType 0) then { _range = parseNumber (str _range); };
if (_range <= 0) then { _range = 50; };
private _password = _module getVariable ["AE3_ModuleRouter_Password", ""];

{
    if (_x getVariable ["AE3_cap_isRouter", false]) then {
        [_x, "", _range, _password] call AE3_network_fnc_applyRouterConfig;
    };
} forEach _syncedUnits;

true

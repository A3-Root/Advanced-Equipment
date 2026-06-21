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
private _gateway = _module getVariable ["AE3_ModuleRouter_Gateway", ""]; // "a.b.c.d", blank = unchanged (#10)

// Routers to configure: the synced ones, or - when nothing was synced (common in Zeus, where syncing
// is fiddly) - every router within the module's wireless range, so the module still does something.
private _targets = _syncedUnits select { _x getVariable ["AE3_cap_isRouter", false] };
if (_targets isEqualTo []) then {
    _targets = (nearestObjects [getPosWorld _module, [], _range max 50]) select { _x getVariable ["AE3_cap_isRouter", false] };
};

diag_log format ["[AE3] ConfigureRouter module: range=%1 password='%2' gateway='%3' targets=%4 (synced=%5)", _range, _password, _gateway, count _targets, count _syncedUnits];

{
    [_x, "", _range, _password, _gateway] call AE3_network_fnc_applyRouterConfig;
} forEach _targets;

true

/*
 * Author: Root
 * Description: Disconnects the selected terminal asset from its current Wi-Fi router, driven by the
 * Disconnect button in the Zeus Asset Attributes router picker. Server-side network teardown.
 * Runs locally on the curator.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Zeus asset attributes display
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_main_fnc_zeus_disconnectFromRouter;
 *
 * Public: No
 */

params ["_display"];

private _entity = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
if (isNull _entity) exitWith {};

if (isNull (_entity getVariable ["AE3_network_parent", objNull])) exitWith
{
    ["AE3 Network", "Not connected to any router.", 5] call BIS_fnc_curatorHint;
};

[_entity] remoteExecCall ["AE3_network_fnc_disconnect", 2];
["AE3 Network", "Disconnected from router.", 5] call BIS_fnc_curatorHint;

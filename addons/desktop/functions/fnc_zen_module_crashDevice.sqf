#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced curator prompt for the Crash Device module. Runs on the placing curator's
 * machine (reached via remoteExec from the server module function). Asks the curator to confirm crashing
 * the resolved laptops through a ZEN Dynamic Dialog, then crashes them (each crash self-routes to the
 * server) and drops the module server-side.
 *
 * Arguments:
 * 0: _moduleNetId <STRING> - netId of the module logic
 * 1: _netIds <ARRAY> - netIds of the target laptops
 *
 * Return Value:
 * None
 *
 * Example:
 * [_moduleNetId, _netIds] call AE3_desktop_fnc_zen_module_crashDevice;
 *
 * Public: No
 */

params ["_moduleNetId", "_netIds"];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_confirm"];
    _args params ["_moduleNetId", "_netIds"];

    if (_confirm) then
    {
        { [objectFromNetId _x] call AE3_power_fnc_crashDevice } forEach _netIds;
        [localize "STR_AE3_Desktop_Config_CrashDeviceDisplayName", format ["Crashed %1 laptop(s).", count _netIds], 5] call BIS_fnc_curatorHint;
    };

    (objectFromNetId _moduleNetId) remoteExec ["deleteVehicle", 2];
};

private _onCancel = {
    params ["_values", "_args"];
    (objectFromNetId (_args select 0)) remoteExec ["deleteVehicle", 2];
};

[
    "STR_AE3_Desktop_Config_CrashDeviceDisplayName",
    [
        ["TOOLBOX:YESNO", format ["Crash %1 laptop(s)?", count _netIds], [false]]
    ],
    _onConfirm,
    _onCancel,
    [_moduleNetId, _netIds]
] call EFUNC(main,zen_createDialog);

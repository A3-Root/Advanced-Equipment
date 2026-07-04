#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add User module. Opens a ZEN Dynamic Dialog on the
 * curator's machine and, on confirm, funnels the input into the same server device-op the legacy
 * curator dialog uses (ae3_main_zeusDeviceOp -> "addUser"). Owns the module lifecycle: the module is
 * deleted on confirm, cancel, or invalid input.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target computer
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _computer] call AE3_main_fnc_zen_module_addUser;
 *
 * Public: No
 */

params ["_module", "_computer"];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_username", "_password"];
    _args params ["_module", "_computer"];

    if (_username isEqualTo "") exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_UsernameMissing"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if (_password isEqualTo "") exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_PasswordMissing"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if ((_username find " ") != -1) exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_UsernameContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };

    ["ae3_main_zeusDeviceOp", [netId _computer, "addUser", [_username, _password], clientOwner]] call CBA_fnc_serverEvent;
    deleteVehicle _module;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "STR_AE3_ArmaOS_Config_AddUserDisplayName",
    [
        ["EDIT", "Username", ["admin"]],
        ["EDIT", "Password", ["admin123"]]
    ],
    _onConfirm,
    _onCancel,
    [_module, _computer]
] call FUNC(zen_createDialog);

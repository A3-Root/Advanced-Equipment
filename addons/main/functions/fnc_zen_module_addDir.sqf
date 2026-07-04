#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add Directory module. Opens a ZEN Dynamic Dialog on
 * the curator's machine and, on confirm, funnels the input into the same server device-op the legacy
 * curator dialog uses (ae3_main_zeusDeviceOp -> "addDir"). Owns the module lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target computer
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _computer] call AE3_main_fnc_zen_module_addDir;
 *
 * Public: No
 */

params ["_module", "_computer"];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_path", "_owner", "_oRead", "_oWrite", "_oExec", "_eRead", "_eWrite", "_eExec"];
    _args params ["_module", "_computer"];

    private _permissions = [[_oRead, _oWrite, _oExec], [_eRead, _eWrite, _eExec]];

    if (_path isEqualTo "") exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_PathMissing"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if (_owner isEqualTo "") exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_OwnerMissing"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if ((_path find " ") != -1) exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_PathContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if ((_owner find " ") != -1) exitWith {
        [objNull, localize "STR_AE3_Main_Zeus_OwnerContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };

    ["ae3_main_zeusDeviceOp", [netId _computer, "addDir", [_path, _owner, _permissions], clientOwner]] call CBA_fnc_serverEvent;
    deleteVehicle _module;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "STR_AE3_Filesystem_Config_AddDirDisplayName",
    [
        ["EDIT", "Path", [""]],
        ["EDIT", "Owner", ["root"]],
        ["CHECKBOX", "Owner: Read", true],
        ["CHECKBOX", "Owner: Write", true],
        ["CHECKBOX", "Owner: Execute", true],
        ["CHECKBOX", "Everyone: Read", true],
        ["CHECKBOX", "Everyone: Write", false],
        ["CHECKBOX", "Everyone: Execute", true]
    ],
    _onConfirm,
    _onCancel,
    [_module, _computer]
] call FUNC(zen_createDialog);

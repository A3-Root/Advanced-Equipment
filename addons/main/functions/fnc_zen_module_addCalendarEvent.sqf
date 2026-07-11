// File: fnc_zen_module_addCalendarEvent.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add Calendar Event module. Opens a ZEN Dynamic
 * Dialog on the curator's machine and, on confirm, funnels the input into the same server device-op
 * the legacy curator dialog uses (ae3_main_zeusDeviceOp -> "addCalendarEvent"). Owns the module
 * lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target computer
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _computer] call AE3_main_fnc_zen_module_addCalendarEvent;
 *
 * Public: No
 */

params ["_module", "_computer"];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_date", "_time", "_title", "_location", "_body"];
    _args params ["_module", "_computer"];

    if (_date isEqualTo "") exitWith {
        [objNull, "Date is required (YYYY-MM-DD)"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };
    if (_title isEqualTo "") exitWith {
        [objNull, "Title is required"] call BIS_fnc_showCuratorFeedbackMessage;
        deleteVehicle _module;
    };

    ["ae3_main_zeusDeviceOp", [netId _computer, "addCalendarEvent", [_date, _title, _location, _body, _time], clientOwner]] call CBA_fnc_serverEvent;
    deleteVehicle _module;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "AE3: Add Calendar Event",
    [
        ["EDIT", "Date (YYYY-MM-DD)", [""]],
        ["EDIT", "Time (HH:MM, blank = all-day)", [""]],
        ["EDIT", "Title", [""]],
        ["EDIT", "Location", [""]],
        ["EDIT:MULTI", "Details", [""]]
    ],
    _onConfirm,
    _onCancel,
    [_module, _computer]
] call FUNC(zen_createDialog);

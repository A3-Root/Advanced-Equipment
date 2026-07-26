// File: fnc_zen_module_addIntel_step2.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add Intel module - step 2. Builds a type-specific ZEN
 * Dynamic Dialog (email, webpage or browser history) and, on confirm, funnels the input into the same
 * shared registry router the legacy dialog uses (AE3_desktop_fnc_intel_dispatch). Owns the module
 * lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target laptop
 * 2: _type <STRING> - "email", "webpage" or "history"
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _laptop, "email"] call AE3_desktop_fnc_zen_module_addIntel_step2;
 *
 * Public: No
 */

params ["_module", "_computer", "_type"];

private _rows = switch (_type) do
{
    case "email":
    {
        [
            ["EDIT", "From", [""]],
            ["EDIT", "To", [""]],
            ["EDIT", "Subject", [""]],
            ["EDIT:MULTI", "Body", [""]],
            ["EDIT", "Received time (optional, HH:MM)", [""]],
            ["TOOLBOX:YESNO", "Create sender mail handle", [false]],
            ["TOOLBOX:YESNO", "Create recipient mail handle", [false]]
        ]
    };
    case "webpage":
    {
        [
            ["EDIT", "URL", [""]],
            ["EDIT", "Title", [""]],
            ["EDIT:MULTI", "Content", [""]]
        ]
    };
    default // history
    {
        [
            ["EDIT", "URL", [""]],
            ["EDIT", "Time (optional, HH:MM)", [""]]
        ]
    };
};

private _onConfirm = {
    params ["_values", "_args"];
    _args params ["_module", "_computer", "_type"];

    private _target = netId _computer;

    switch (_type) do
    {
        case "email":
        {
            _values params ["_from", "_to", "_subject", "_body", "_recv", "_createFrom", "_createTo"];
            ["email", _target, _from, _to, _subject, _body, [_recv, _createFrom, _createTo]] call FUNC(intel_dispatch);
        };
        case "webpage":
        {
            _values params ["_url", "_title", "_content"];
            // The registry splits the content on "|"; collapse the multi-line edit's breaks into that.
            private _joined = (_content splitString (toString [10, 13])) joinString "|";
            ["webpage", _target, _url, _title, _joined] call FUNC(intel_dispatch);
        };
        default // history
        {
            _values params ["_url", "_time"];
            ["history", _target, _url, _time] call FUNC(intel_dispatch);
        };
    };

    [localize "STR_AE3_Desktop_Config_AddIntelDisplayName", format ["%1 -> %2", _type, [_computer] call FUNC(deviceLabel)], 5] call BIS_fnc_curatorHint;

    deleteVehicle _module;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "STR_AE3_Desktop_Config_AddIntelDisplayName",
    _rows,
    _onConfirm,
    _onCancel,
    [_module, _computer, _type]
] call EFUNC(main,zen_createDialog);

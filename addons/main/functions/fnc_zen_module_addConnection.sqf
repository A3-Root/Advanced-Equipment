#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add Connection module. Opens a ZEN Dynamic Dialog on
 * the curator's machine for the two synced endpoints and, on confirm, creates the chosen connection via
 * the shared AE3_main_fnc_zeus_applyConnection helper. Owns the module lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _from <OBJECT> - First synced device
 * 2: _to <OBJECT> - Second synced device
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _laptop, _router] call AE3_main_fnc_zen_module_addConnection;
 *
 * Public: No
 */

params ["_module", "_from", "_to"];

private _fromName = [_from, true] call ace_cargo_fnc_getNameItem;
private _toName = [_to, true] call ace_cargo_fnc_getNameItem;
private _title = format ["%1: %2 -> %3", localize "STR_AE3_Main_Config_ModuleAddConnectionDisplayName", _fromName, _toName];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_typeIndex", "_switch"];
    _args params ["_module", "_from", "_to"];

    private _type = ["AE3_PowerConnection", "AE3_NetworkConnection"] select _typeIndex;
    [_from, _to, _type, _switch, _module] call FUNC(zeus_applyConnection);
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    _title,
    [
        ["COMBO", "Connection type", [[0, 1], ["Power connection", "Network connection"], 0]],
        ["CHECKBOX", "Swap source / target", false]
    ],
    _onConfirm,
    _onCancel,
    [_module, _from, _to]
] call FUNC(zen_createDialog);

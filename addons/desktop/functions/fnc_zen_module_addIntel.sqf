#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Add Intel module - step 1. Opens a ZEN Dynamic Dialog
 * to pick the intel type. Email/webpage/history continue to a type-specific ZEN step-2 dialog; media and
 * lockedfile reopen the legacy curator dialog because they rely on AE3's filesystem Browse picker, which
 * ZEN cannot host. Owns the module lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target laptop
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _laptop] call AE3_desktop_fnc_zen_module_addIntel;
 *
 * Public: No
 */

params ["_module", "_computer"];

if (isNull _computer) exitWith
{
    [localize "STR_AE3_Desktop_Config_AddIntelDisplayName", "Place the module on a laptop.", 5] call BIS_fnc_curatorHint;
    deleteVehicle _module;
};

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_type"];
    _args params ["_module", "_computer"];

    // Media and lockedfile keep the legacy dialog for its filesystem Browse picker; reopen it next
    // frame with the laptop already resolved and the ZEN handoff flag cleared so it runs normally.
    if (_type in ["media", "lockedfile"]) exitWith
    {
        [{
            params ["_module", "_computer"];
            missionNamespace setVariable ["BIS_fnc_initCuratorAttributes_target", _module];
            uiNamespace setVariable ["AE3_desktop_intelZenOverride", [_module, _computer]];
            _module setVariable [QGVAR(zenHandled), false];
            createDialog "AE3_UserInterface_Zeus_Module_AddIntel";
        }, [_module, _computer]] call CBA_fnc_execNextFrame;
    };

    [FUNC(zen_module_addIntel_step2), [_module, _computer, _type]] call CBA_fnc_execNextFrame;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "STR_AE3_Desktop_Config_AddIntelDisplayName",
    [
        ["COMBO", "Intel type", [
            ["email", "webpage", "history", "media", "lockedfile"],
            ["Email", "Webpage", "Browser history", "Media", "Locked file"],
            0
        ]]
    ],
    _onConfirm,
    _onCancel,
    [_module, _computer]
] call EFUNC(main,zen_createDialog);

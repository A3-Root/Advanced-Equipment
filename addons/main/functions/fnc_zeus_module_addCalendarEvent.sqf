#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Handles the Zeus 'Add Calendar Event' module interface events (onLoad/onUnload). Runs
 * locally on the Zeus curator's machine. Adds a calendar/intel event to the target computer via the
 * server-side device-op handler (ae3_main_zeusDeviceOp -> "addCalendarEvent"). Mirrors
 * AE3_main_fnc_zeus_module_addUser. The module is deleted after processing. When Zeus Enhanced is
 * loaded, the input is gathered through a ZEN Dynamic Dialog instead of the built-in dialog.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Zeus module display
 * 1: _exitCode <NUMBER> - Exit code (1 = OK, 2 = Cancel)
 * 2: _event <STRING> - Event type ("onLoad" or "onUnload")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 1, "onUnload"] call AE3_main_fnc_zeus_module_addCalendarEvent;
 *
 * Public: No
 */

params ["_display", "_exitCode", "_event"];

private _module = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
if (isNull _module) exitWith {};

/* ---------------------------------------- */

if (_event isEqualTo "onLoad") exitWith
{
    private _result = [_display] call AE3_main_fnc_zeus_checkForComputer;
    _result params ["_status", "_computer"];

    if (_status isNotEqualTo "SUCCESS") exitWith { _display closeDisplay 2; };

    // Hand off to ZEN's Dynamic Dialog when Zeus Enhanced is present.
    if (EGVAR(main,hasZenDialog)) exitWith
    {
        _module setVariable [QGVAR(zenHandled), true];
        _display closeDisplay 2;
        [FUNC(zen_module_addCalendarEvent), [_module, _computer]] call CBA_fnc_execNextFrame;
    };

    _display setVariable ["AE3_linkedComputer", _computer];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
    if (_module getVariable [QGVAR(zenHandled), false]) exitWith {}; // ZEN owns the lifecycle

    private _computer = _display getVariable ["AE3_linkedComputer", objNull];
    if ((isNull _computer) || (_exitCode == 2)) exitWith
    {
        deleteVehicle _module;
    };

    private _date     = ctrlText (_display displayCtrl 1401);
    private _title    = ctrlText (_display displayCtrl 1402);
    private _location = ctrlText (_display displayCtrl 1403);
    private _body     = ctrlText (_display displayCtrl 1404);

    if (_date isEqualTo "") exitWith { [objNull, "Date is required (YYYY-MM-DD)"] call BIS_fnc_showCuratorFeedbackMessage; };
    if (_title isEqualTo "") exitWith { [objNull, "Title is required"] call BIS_fnc_showCuratorFeedbackMessage; };

    ["ae3_main_zeusDeviceOp", [netId _computer, "addCalendarEvent", [_date, _title, _location, _body], clientOwner]] call CBA_fnc_serverEvent;

    deleteVehicle _module;
};

/* ---------------------------------------- */

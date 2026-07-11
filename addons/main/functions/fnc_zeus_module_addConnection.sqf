// File: fnc_zeus_module_addConnection.sqf
#include "..\script_component.hpp"
/*
 * Author: Root, y0014984
 * Description: Handles the Zeus "Add Connection" module interface events (onLoad and onUnload). On load, populates the UI with
 * synced objects and validates that exactly two objects are connected. On unload, creates the selected connection type
 * (power or network) between the two synced objects after validation. Runs locally on the curator's machine and deletes the
 * module after successful processing. When Zeus Enhanced is loaded, the input is gathered through a ZEN Dynamic Dialog
 * instead of the built-in dialog.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Zeus module interface display
 * 1: _exitCode <NUMBER> - Exit code from the display (1 = OK, 2 = Cancel)
 * 2: _event <STRING> - Event type ("onLoad" or "onUnload")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 1, "onUnload"] call AE3_main_fnc_zeus_module_addConnection;
 *
 * Public: No
 */

params ["_display", "_exitCode", "_event"];

// der folgende Code funktioniert irgendwie nicht
private _module = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
if (isNull _module) exitWith {};

/* ---------------------------------------- */

if (_event isEqualTo "onLoad") then
{
    private _syncedObjects = synchronizedObjects _module;

    // remove connection to itself
    _module synchronizeObjectsRemove [_module];

    // remove all unnecessary connections
    if ((count _syncedObjects) > 2) then
    {
        // Extract connections to delete BEFORE modifying the array (deleteRange returns Nothing, not the deleted elements)
        private _connectionsToDelete = _syncedObjects select [2, (count _syncedObjects) - 2];
        _syncedObjects deleteRange [2, (count _syncedObjects) - 2];
        _module synchronizeObjectsRemove _connectionsToDelete;
    };

    // Route through ZEN's Dynamic Dialog when Zeus Enhanced is present; needs two synced endpoints.
    if (EGVAR(main,hasZenDialog)) exitWith
    {
        _module setVariable [QGVAR(zenHandled), true];
        _display closeDisplay 2;
        if ((count _syncedObjects) < 2) exitWith
        {
            [objNull, localize "STR_AE3_Main_Zeus_ToMissing"] call BIS_fnc_showCuratorFeedbackMessage;
            deleteVehicle _module;
        };
        [FUNC(zen_module_addConnection), [_module, _syncedObjects select 0, _syncedObjects select 1]] call CBA_fnc_execNextFrame;
    };

    // set ok button state
    private _okCtrl = _display getVariable ["okCtrl", objNull];
    if ((count _syncedObjects) > 1) then
    {
        _okCtrl ctrlEnable true;
    }
    else
    {
        _okCtrl ctrlEnable false;
    };

    // fill 'From' field
    if (_syncedObjects isNotEqualTo []) then
    {
        private _from = _syncedObjects select 0;
        private _fromNameWithAceCargoName = [_from, true] call ace_cargo_fnc_getNameItem;
        private _fromCtrl = _display displayCtrl 1401;
        _fromCtrl ctrlSetText _fromNameWithAceCargoName;
        _display setVariable ["entity1", _from];
    };

    // fill 'To' field
    if ((count _syncedObjects) > 1) then
    {
        private _to = _syncedObjects select 1;
        private _toNameWithAceCargoName = [_to, true] call ace_cargo_fnc_getNameItem;
        private _toCtrl = _display displayCtrl 1402;
        _toCtrl ctrlSetText _toNameWithAceCargoName;
        _display setVariable ["entity2", _to];
    };

    // close display on first start because there are no connections set up and configuring makes no sense without connections
    private _firstStart = _module getVariable ["firstStart", nil];
    if ( isNil "_firstStart") then { _firstStart = true; } else { _firstStart = false; };
    _module setVariable ["firstStart", _firstStart];
    if (_firstStart) exitWith { _display closeDisplay 2; }; // 2 = cancel
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") then
{
    // 2 = canceled dialog
    if (_exitCode == 2) exitWith {};

    // get Settings from UI
    private _typeCtrl = _display displayCtrl 1501;
    private _type = lbCurSel _typeCtrl; // 0 = Power Connection; 1 = Network Connection
    if (_type == 0) then { _type = "AE3_PowerConnection"; } else { _type = "AE3_NetworkConnection"; };

    // get Data from Display namespace
    private _from = _display getVariable ["entity1", objNull];
    private _to = _display getVariable ["entity2", objNull];
    private _switch = _display getVariable ['switch', false];

    [_from, _to, _type, _switch, _module] call FUNC(zeus_applyConnection);
};

/* ---------------------------------------- */

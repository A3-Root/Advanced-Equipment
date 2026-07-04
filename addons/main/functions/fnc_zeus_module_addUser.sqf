#include "..\script_component.hpp"
/*
 * Author: Root, y0014984
 * Description: Handles the Zeus 'Add User' module interface events (onLoad/onUnload). Runs locally on the Zeus curator's machine.
 * Creates a new user account on the target computer with the specified username and password.
 * The module must be placed on a computer object and will be deleted after processing. When Zeus Enhanced is loaded,
 * the input is gathered through a ZEN Dynamic Dialog instead of the built-in dialog.
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
 * [_display, 1, "onUnload"] call AE3_main_fnc_zeus_module_addUser;
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

    if (_status isNotEqualTo "SUCCESS") exitWith { _display closeDisplay 2; }; // 2 = cancel

    // Hand off to ZEN's Dynamic Dialog when Zeus Enhanced is present; the module lifecycle then
    // belongs to the ZEN builder, so the legacy onUnload below is skipped via the zenHandled flag.
    if (EGVAR(main,hasZenDialog)) exitWith
    {
        _module setVariable [QGVAR(zenHandled), true];
        _display closeDisplay 2;
        [FUNC(zen_module_addUser), [_module, _computer]] call CBA_fnc_execNextFrame;
    };

    // add computer variable to display namespace
    _display setVariable ["AE3_linkedComputer", _computer];
};

/* ---------------------------------------- */

if (_event isEqualTo "onUnload") exitWith
{
    if (_module getVariable [QGVAR(zenHandled), false]) exitWith {}; // ZEN owns the lifecycle

    private _computer = _display getVariable ["AE3_linkedComputer", objNull];
    if ((isNull _computer) || (_exitCode == 2)) exitWith
    {
        // delete module if dialog cancelled or computer not linked to module
        deleteVehicle _module;
    };

    // get username and password from UI
    private _usernameCtrl = _display displayCtrl 1401;
    private _passwordCtrl = _display displayCtrl 1402;
    private _username = ctrlText _usernameCtrl;
    private _password = ctrlText _passwordCtrl;

    // check for empty but mandatory input fields
    // module is still there an could be opened and filled in with valid input
    // but currently, this case will be catched by UI logic, defined directly in config
    if(_username isEqualTo "") exitWith { [objNull, localize "STR_AE3_Main_Zeus_UsernameMissing"] call BIS_fnc_showCuratorFeedbackMessage; };
    if(_password isEqualTo "") exitWith { [objNull, localize "STR_AE3_Main_Zeus_PasswordMissing"] call BIS_fnc_showCuratorFeedbackMessage; };

    // check for not allowed spaces in username
    if((_username find " ") != -1) exitWith { [objNull, localize "STR_AE3_Main_Zeus_UsernameContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage; };

    // Server ensures the filesystem is initialized (on demand) and reports back via
    // "ae3_main_zeusOpFeedback" - no client-side polling (fixes timeouts on dedicated)
    ["ae3_main_zeusDeviceOp", [netId _computer, "addUser", [_username, _password], clientOwner]] call CBA_fnc_serverEvent;

    deleteVehicle _module;
};

/* ---------------------------------------- */

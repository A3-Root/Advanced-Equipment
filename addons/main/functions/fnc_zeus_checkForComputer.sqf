/*
 * Author: Root, y0014984
 * Description: Helper function for Zeus modules that validates the target object.
 * Checks if the module was placed on an object with a filesystem and that the computer is not currently in use (via ace_mutex check).
 * Provides Zeus feedback messages on error.
 *
 * Arguments:
 * None (uses BIS_fnc_curatorObjectPlaced_mouseOver from mission namespace)
 *
 * Return Value:
 * Array with status and computer object <ARRAY>:
 * 0: _status <STRING> - "SUCCESS" or "ERROR"
 * 1: _computer <OBJECT> - The computer object, or objNull on error
 *
 * Example:
 * private _result = [] call AE3_main_fnc_zeus_checkForComputer;
 * _result params ["_status", "_computer"];
 *
 * Public: No
 */

private _mouseOver = missionNamespace getVariable ["BIS_fnc_curatorObjectPlaced_mouseOver", [""]];
_mouseOver params ["_mouseOverType", "_mouseOverUnit"];

// check if module was placed on top of another object
if (_mouseOverType != "OBJECT") exitWith
{
    [objNull, localize "STR_AE3_Main_Zeus_NoComputer"] call BIS_fnc_showCuratorFeedbackMessage;

    ["ERROR", objNull];
};

private _computer = _mouseOverUnit;

// An AE3 device is identified by its AE3_Device config - no server round trip needed.
// This also catches the common mistake of placing the vanilla laptop prop instead of
// the AE3 variant (e.g. Land_Laptop_03_black_F vs Land_Laptop_03_black_F_AE3).
if (!isClass (configOf _computer >> "AE3_Device")) exitWith
{
    private _message = if ((typeOf _computer) find "Laptop" >= 0) then
    {
        localize "STR_AE3_Main_Zeus_NotAe3Device"
    }
    else
    {
        localize "STR_AE3_Main_Zeus_NoComputer"
    };

    [objNull, _message] call BIS_fnc_showCuratorFeedbackMessage;

    ["ERROR", objNull];
};

// check if computer is currently used by checking the mutex variable
if (!isNull (_computer getVariable ['AE3_computer_mutex', objNull])) exitWith
{
    [objNull, localize "STR_AE3_Main_Zeus_ComputerInUse"] call BIS_fnc_showCuratorFeedbackMessage;

    ["ERROR", objNull];
};

["SUCCESS", _computer];

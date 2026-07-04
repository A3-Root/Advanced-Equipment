#include "..\script_component.hpp"
/*
 * Author: Root, y0014984
 * Description: Handles the Zeus 'Add File' module interface events (onLoad/onUnload). Runs locally on the Zeus curator's machine.
 * Creates a new file on the target computer's filesystem with specified content, permissions, and optional encryption.
 * The module must be placed on an object with a filesystem and will be deleted after processing. When Zeus Enhanced is loaded,
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
 * [_display, 1, "onUnload"] call AE3_main_fnc_zeus_module_addFile;
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

    // Hand off to ZEN's Dynamic Dialog when Zeus Enhanced is present.
    if (EGVAR(main,hasZenDialog)) exitWith
    {
        _module setVariable [QGVAR(zenHandled), true];
        _display closeDisplay 2;
        [FUNC(zen_module_addFile), [_module, _computer]] call CBA_fnc_execNextFrame;
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

    // get values from UI
    private _pathCtrl = _display displayCtrl 1401;
    private _contentCtrl = _display displayCtrl 1402;
    private _isCodeCtrl = _display displayCtrl 1301;
    private _ownerCtrl = _display displayCtrl 1403;
    private _ownerReadCtrl = _display displayCtrl 1302;
    private _ownerWriteCtrl = _display displayCtrl 1303;
    private _ownerExecuteCtrl = _display displayCtrl 1304;
    private _everyoneReadCtrl = _display displayCtrl 1305;
    private _everyoneWriteCtrl = _display displayCtrl 1306;
    private _everyoneExecuteCtrl = _display displayCtrl 1307;
    private _enableEncryptionCtrl = _display displayCtrl 1308;
    private _encryptionAlgorithmCtrl = _display displayCtrl 1501;
    private _encryptionKeyCtrl = _display displayCtrl 1405;
    private _path = ctrlText _pathCtrl;
    private _content = ctrlText _contentCtrl;
    private _isCode = cbChecked _isCodeCtrl;
    private _owner = ctrlText _ownerCtrl;
    private _ownerRead = cbChecked _ownerReadCtrl;
    private _ownerWrite = cbChecked _ownerWriteCtrl;
    private _ownerExecute = cbChecked _ownerExecuteCtrl;
    private _everyoneRead = cbChecked _everyoneReadCtrl;
    private _everyoneWrite = cbChecked _everyoneWriteCtrl;
    private _everyoneExecute = cbChecked _everyoneExecuteCtrl;
    private _permissions = [[_ownerRead, _ownerWrite, _ownerExecute], [_everyoneRead, _everyoneWrite, _everyoneExecute]];
    private _enableEncryption = cbChecked _enableEncryptionCtrl;
    private _encryptionAlgorithm = lbCurSel _encryptionAlgorithmCtrl; // 0 = Caesar; 1 = Columnar
    private _encryptionKey = ctrlText _encryptionKeyCtrl;

    if (_encryptionAlgorithm == 0) then { _encryptionAlgorithm = "caesar"; } else { _encryptionAlgorithm = "columnar"; };

    // check for empty but mandatory input fields
    // module is still there an could be opened and filled in with valid input
    // but currently, this case will be catched by UI logic, defined directly in config
    if(_path isEqualTo "") exitWith { [objNull, localize "STR_AE3_Main_Zeus_PathMissing"] call BIS_fnc_showCuratorFeedbackMessage; };
    if(_owner isEqualTo "") exitWith { [objNull, localize "STR_AE3_Main_Zeus_OwnerMissing"] call BIS_fnc_showCuratorFeedbackMessage; };
    if(_encryptionKey isEqualTo "") exitWith { [objNull, localize "STR_AE3_Main_Zeus_KeyMissing"] call BIS_fnc_showCuratorFeedbackMessage; };

    // check for not allowed spaces in path and owner
    if((_path find " ") != -1) exitWith { [objNull, localize "STR_AE3_Main_Zeus_PathContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage; };
    if((_owner find " ") != -1) exitWith { [objNull, localize "STR_AE3_Main_Zeus_OwnerContainsSpaces"] call BIS_fnc_showCuratorFeedbackMessage; };

    // Server ensures the filesystem is initialized (on demand) and reports back via
    // "ae3_main_zeusOpFeedback" - no client-side polling (fixes timeouts on dedicated)
    ["ae3_main_zeusDeviceOp", [netId _computer, "addFile", [_path, _content, _isCode, _owner, _permissions, _enableEncryption, _encryptionAlgorithm, _encryptionKey], clientOwner]] call CBA_fnc_serverEvent;

    deleteVehicle _module;
};

/* ---------------------------------------- */

/*
 * Author: Root, y0014984
 * Description: Handles the Zeus Asset Attributes interface on unload. Runs locally on the Zeus curator's machine.
 * Updates battery level and/or fuel level for the selected device based on slider values set by the curator.
 * Terminates the status update loop and provides feedback on changes made.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Zeus asset attributes display
 * 1: _exitCode <NUMBER> - Exit code (1 = OK, 2 = Cancel)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 1] call AE3_main_fnc_zeus_updateAttributes;
 *
 * Public: No
 */

params ["_display", "_exitCode"];
// _exitCode: ok = 1, cancel = 2

/* ======================================== */

private _statusUpdateHandle = _display getVariable ["AE3_statusUpdateHandle", scriptNull];
if (!isNull _statusUpdateHandle) then { terminate _statusUpdateHandle; };

if (_exitCode == 1) then
{
    /* ======================================== */
    
    private _entity = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
    if (isNull _entity) exitWith {};

    private _battery = _entity;
    private _hasInternal = _entity getVariable "AE3_power_hasInternal";
    if (_hasInternal) then { _battery = _entity getVariable "AE3_power_internal"; };

    private _generator = _entity;

    /* ======================================== */

    private _message = "";

    /* ======================================== */

    // if asset has battery, update battery level
    if (!isNil { _battery getVariable "AE3_power_batteryCapacity" }) then
    {
        private _batteryLevelCtrl = _display displayCtrl 1900;
        private _batteryLevelPercent = sliderPosition _batteryLevelCtrl;

        _message = _message + format [localize "STR_AE3_Main_Zeus_NewBatteryLevel", _batteryLevelPercent, "%"];

        [_battery, _batteryLevelPercent] remoteExecCall ["AE3_power_fnc_setBatteryLevel", 2];
    };

    /* ======================================== */

    // if asset has fuel, update fuel level
    if (!isNil { _generator getVariable "AE3_power_fuelCapacity" }) then
    {
        private _fuelLevelCtrl = _display displayCtrl 1901;
        private _fuelLevelPercent = sliderPosition _fuelLevelCtrl;

        _message = _message + format [localize "STR_AE3_Main_Zeus_NewFuelLevel", _fuelLevelPercent, "%"];

        [_generator, _fuelLevelPercent] call AE3_power_fnc_setFuelLevel;
    };

    /* ======================================== */

    // Router-only wireless config (#1/#10): apply the Wireless Range + Gateway fields server-side.
    if (_entity getVariable ["AE3_cap_isRouter", false]) then
    {
        private _range = parseNumber (ctrlText (_display displayCtrl 1910));
        private _gateway = ctrlText (_display displayCtrl 1911);
        [_entity, "", _range, _entity getVariable ["AE3_network_password", ""], _gateway] remoteExecCall ["AE3_network_fnc_applyRouterConfig", 2];
        _message = _message + format ["Wireless range: %1 m. Gateway: %2.", _range, _gateway];
    };

    /* ======================================== */

    ["AE3 Asset Attributes changed", _message, 5] call BIS_fnc_curatorHint;

    /* ======================================== */
};

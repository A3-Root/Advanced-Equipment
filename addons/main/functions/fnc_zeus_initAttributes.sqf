/*
 * Author: Root, y0014984
 * Description: Initializes the Zeus Asset Attributes interface on load. Runs locally on the Zeus curator's machine.
 * Gathers and displays information about the selected AE3 asset including power status, power output, power requirements, IP address, fuel level, and battery level.
 * Continuously updates the display with live asset information.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Zeus asset attributes display
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_main_fnc_zeus_initAttributes;
 *
 * Public: No
 */

params ["_display"];

private _entity = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
if (isNull _entity) exitWith {};

// The interface is shown up too fast; waitUntil the variables are valid
// The interface is faster then our init process for object variables
// on my test system it takes 3 waitUntil cycles for the variables to be available

[_display, _entity] spawn
{
    params ["_display", "_entity"];

    /* ======================================== */

    private _headlineCtrl = _display displayCtrl 1000;

	//private _config = configFile >> "CfgVehicles" >> (typeOf _entity);
    //private _displayName = getText (_config >> "displayName");
    private _displayName = [_entity, true] call ace_cargo_fnc_getNameItem;
	_headlineCtrl ctrlSetText format [localize "STR_AE3_Main_Zeus_ObjectHeader", _displayName];

    // Derive device status directly from config (compileDevice no longer broadcasts this per object).
    private _isPowerDevice = isClass (configOf _entity >> "AE3_Device");

    // This could be the case for the desk
    if (!_isPowerDevice) exitWith {};

    // wait for asset init to finish
    waitUntil { !isNil { _entity getVariable "AE3_power_initDone" }; };

    /* ======================================== */

    private _statusUpdateHandle = [_display, _entity] spawn
    {
        params ["_display", "_entity"];

        while { true; } do
        {
            private _statusCtrl = _display displayCtrl 1400;
            private _status = [];

            _status pushBack localize "STR_AE3_Main_Zeus_ObjectStatus";
            _status pushBack "------------";

            // Class Name
            private _className = typeOf _entity;
            _status pushBack (format [localize "STR_AE3_Main_Zeus_ClassName", _className]);

            // Power State
            private _powerState = [_entity] call AE3_power_fnc_getPowerState;
            _status pushBack (format [localize "STR_AE3_Power_Interaction_PowerStateHint", _powerState]);

            // Power Output
            private _powerCap = _entity getVariable ['AE3_power_powerCapacity', 0];
            private _prefix = "k"; // kWatts
            _powerCap = _powerCap * 3600;
            if (_powerCap < 1.0) then
            {
                _powerCap = _powerCap * 1000;
                _prefix = "";
            };
            _status pushBack (format [localize "STR_AE3_Power_Interaction_PowerOutputHint", _powerCap, _prefix]);

            // Power Required
            private _powerReq = _entity getVariable ["AE3_power_powerReq", 0];
            _prefix = "k"; // kWatts
            _powerReq = _powerReq * 3600;
            if (_powerReq < 1.0) then
            {
                _powerReq = _powerReq * 1000;
                _prefix = "";
            };
            _status pushBack (format [localize "STR_AE3_Power_Interaction_PowerReqHint", _powerReq, _prefix]);

            // IP Address
            private _ip = _entity getVariable ["AE3_network_address", []];
            private _ipString = [_ip] call AE3_network_fnc_ip2str;
            _status pushBack (format ["%1: %2", localize "STR_AE3_Network_General_IpAddress", _ipString]);

            // Connections overview (power + network, incoming and outgoing)
            _status pushBack "------------";

            private _powerProvider = _entity getVariable ["AE3_power_powerCableDevice", objNull];
            if (!isNull _powerProvider) then
            {
                _status pushBack (format ["Power source: %1", [_powerProvider, true] call ace_cargo_fnc_getNameItem]);
            };

            private _connectedPowerDevices = _entity getVariable ["AE3_power_connectedDevices", []];
            if (_connectedPowerDevices isNotEqualTo []) then
            {
                _status pushBack (format ["Powered devices: %1", count _connectedPowerDevices]);
                {
                    _status pushBack (format ["  - %1", [_x, true] call ace_cargo_fnc_getNameItem]);
                } forEach _connectedPowerDevices;
            };

            private _networkParent = _entity getVariable ["AE3_network_parent", objNull];
            if (!isNull _networkParent) then
            {
                _status pushBack (format ["Network gateway: %1 (%2)", [_networkParent, true] call ace_cargo_fnc_getNameItem, [_networkParent getVariable ["AE3_network_address", [127,0,0,1]]] call AE3_network_fnc_ip2str]);
            };

            private _networkChildren = _entity getVariable ["AE3_network_children", []];
            if (_networkChildren isNotEqualTo []) then
            {
                _status pushBack (format ["Network clients: %1", count _networkChildren]);
                {
                    _status pushBack (format ["  - %1 (%2)", [_x, true] call ace_cargo_fnc_getNameItem, [_x getVariable ["AE3_network_address", [127,0,0,1]]] call AE3_network_fnc_ip2str]);
                } forEach _networkChildren;
            };

            private _statusString = _status joinString endl;
            _statusCtrl ctrlSetText _statusString;

            sleep 1;
        };
    };

    _display setVariable ["AE3_statusUpdateHandle", _statusUpdateHandle];

    /* ======================================== */

    private _batteryLevelSliderCtrl = _display displayCtrl 1900;
    private _batteryLevelCtrl = _display displayCtrl 1401;
    private _fuelLevelSliderCtrl = _display displayCtrl 1901;
    private _fuelLevelCtrl = _display displayCtrl 1402;

    private _battery = _entity;
    private _hasInternal = _entity getVariable "AE3_power_hasInternal";
    if (_hasInternal) then { _battery = _entity getVariable "AE3_power_internal"; };

    private _generator = _entity;

    /* ======================================== */

    // if asset has battery, init battery level controls
    if (!isNil { _battery getVariable "AE3_power_batteryCapacity" }) then
    {
        // enable controls
        _batteryLevelSliderCtrl ctrlEnable true;
        _batteryLevelCtrl ctrlEnable true;

        private _result = [_battery] call AE3_power_fnc_getBatteryLevel;
        _result params ["_batteryLevel", "_batteryLevelPercent", "_batteryCapacity"];
        
        _batteryLevelPercent = round _batteryLevelPercent;

        _batteryLevelSliderCtrl sliderSetPosition _batteryLevelPercent;
        _batteryLevelCtrl ctrlSetText format ['%1%2', _batteryLevelPercent, '%'];
    };

    /* ======================================== */

    // if asset has fuel, init fuel level controls
    if (!isNil { _generator getVariable "AE3_power_fuelCapacity" }) then
    {
        // enable controls
        _fuelLevelSliderCtrl ctrlEnable true;
        _fuelLevelCtrl ctrlEnable true;

        private _result = [_generator] call AE3_power_fnc_getFuelLevel;
        _result params ["_fuelLevel", "_fuelLevelPercent", "_fuelCapacity"];

        _fuelLevelPercent = round _fuelLevelPercent;

        _fuelLevelSliderCtrl sliderSetPosition _fuelLevelPercent;
        _fuelLevelCtrl ctrlSetText format ['%1%2', _fuelLevelPercent, '%'];
    };

    /* ======================================== */
};

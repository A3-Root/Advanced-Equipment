#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Crashes a computer: the device becomes unusable (terminal inaccessible, blue
 * crash screen) until it is turned off and on again. Any open terminal session is force-closed
 * and the mutex released. Can be called from any machine; execution is routed to the server.
 * Power state values: 0 = off, 1 = on, 2 = standby, 3 = crashed.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object to crash
 *
 * Return Value:
 * true if the crash was applied/requested, false if the device was not running <BOOL>
 *
 * Example:
 * [_laptop] call AE3_power_fnc_crashDevice;
 *
 * Public: Yes
 */

params ["_computer"];

if (isNull _computer) exitWith { false };

if (!isServer) exitWith
{
	["ae3_power_crashDevice", [_computer]] call CBA_fnc_serverEvent;
	true
};

// Only a running or standby device can crash
private _powerState = _computer getVariable ["AE3_power_powerState", 0];
if !(_powerState in [1, 2]) exitWith { false };

// Force-close an open terminal session on the using player's machine
private _mutexHolder = _computer getVariable ["AE3_computer_mutex", objNull];
if (!isNull _mutexHolder) then
{
	["ae3_armaos_forceCloseTerminal", [_computer], _mutexHolder] call CBA_fnc_targetEvent;
};
_computer setVariable ["AE3_computer_mutex", objNull, true];

_computer setVariable ["AE3_power_powerState", 3, true];

// Crash screen (procedural blue screen) - setObjectTextureGlobal must run where the object is local
[_computer, [1, "#(argb,8,8,3)color(0,0.05,0.4,1,co)"]] remoteExecCall ["setObjectTextureGlobal", _computer];

// A crashed device draws no power
[_computer, 0] call AE3_power_fnc_updateSelfPower;

INFO_1("Device crashed: %1",typeOf _computer);

true

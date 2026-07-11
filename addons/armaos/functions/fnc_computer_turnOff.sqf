// File: fnc_computer_turnOff.sqf
#include "..\script_component.hpp"
/*
 * Author: Root, Wasserstoff, y0014984
 * Description: Executes the turn off operation for a given computer object. Computer texture changes to show shutdown animation and clears terminal state.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object to turn off
 * 1: _silent <BOOL> (Optional, default: false) - Whether to suppress sounds
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [_computer] call AE3_armaos_fnc_computer_turnOff;
 *
 * Public: Yes
 */

params ["_computer", ["_silent", false]];

private _turnOffTime = AE3_ShutdownTime;

if (AE3_DebugMode) then { _turnOffTime = 3; };

// Shutdown animation: 4 texture frames spread over the shutdown time
for "_i" from 0 to 3 do
{
	[
		{
			params ["_computer", "_frame"];
			_computer setObjectTextureGlobal [1, format ["\z\ae3\addons\armaos\textures\Laptop_4_to_3_Shutting_Down_%1.paa", _frame]];
		},
		[_computer, _i],
		_i * (_turnOffTime / 4.0)
	] call CBA_fnc_waitAndExecute;
};

[
	{
		params ["_computer", "_silent"];

		_computer setObjectTextureGlobal [1, "#(argb,8,8,3)color(0,0,0,0.0,co)"];

		if (!_silent) then
		{
			[_computer] call AE3_armaos_fnc_computer_playSoundStop;
		};

		// Clear terminal and sync data
		_computer setVariable ["AE3_terminal", nil];
		_computer setVariable ["AE3_terminal_sync", nil, [clientOwner, 2]];
	},
	[_computer, _silent],
	_turnOffTime
] call CBA_fnc_waitAndExecute;

true;

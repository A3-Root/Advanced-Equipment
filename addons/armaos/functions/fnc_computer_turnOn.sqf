/*
 * Author: Root, Wasserstoff, y0014984
 * Description: Executes the turn on operation for a given computer object. Computer texture changes to show booting animation and plays startup sound.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object to turn on
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [_computer] call AE3_armaos_fnc_computer_turnOn;
 *
 * Public: Yes
 */

params ["_computer"];

private _powerState = _computer getVariable 'AE3_power_powerState';

private _turnOnTime = 0;

if (_powerState == 0) then
{
	// Cold boot - use CBA setting
	_turnOnTime = AE3_StartupTime;
}
else
{
	// Warm boot from standby - always 3 seconds
	_turnOnTime = 3;
};

if (AE3_DebugMode) then { _turnOnTime = 3; };

for "_i" from 0 to 3 do
{
	if (_i isEqualTo 0) then
	{
		_computer setObjectTextureGlobal [1, format ["\z\ae3\addons\armaos\textures\Laptop_4_to_3_Booting_%1.paa", _i]];
	}
	else
	{
		[
			{
				params ["_computer", "_frame"];
				_computer setObjectTextureGlobal [1, format ["\z\ae3\addons\armaos\textures\Laptop_4_to_3_Booting_%1.paa", _frame]];
			},
			[_computer, _i],
			_i * (_turnOnTime / 4.0)
		] call CBA_fnc_waitAndExecute;
	};

};

// Default powered-on/idle screen is the GUI image (a copy of Laptop_4_to_3_On.paa for now, so it
// can be reskinned independently). The CLI/terminal restores Laptop_4_to_3_On.paa on close.
[
	{
		params ["_computer"];
		_computer setObjectTextureGlobal [1, "\z\ae3\addons\armaos\textures\Laptop_PowerOn.paa"];
		[_computer] call AE3_armaos_fnc_computer_playSoundStart;
	},
	[_computer],
	_turnOnTime
] call CBA_fnc_waitAndExecute;


true;

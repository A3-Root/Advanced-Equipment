// File: fnc_attr_addGames.sqf
/*
 * Author: Root
 * Description: Eden object-attribute helper. Adds the chosen games to a laptop once it has finished
 * initialising, so the attribute can be set in the editor and applied at mission start regardless of
 * init ordering. Server-only; a no-op when no game is requested.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop object
 * 1: _isSnake <BOOL> - Add the Snake game
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, true] call AE3_armaos_fnc_attr_addGames;
 *
 * Public: No
 */

params ["_computer", ["_isSnake", false]];

if (!isServer) exitWith {};
if (!_isSnake) exitWith {};

[
	{ params ["_computer"]; !isNull _computer && {_computer getVariable ["AE3_cap_hasTerminal", false]} },
	{ params ["_computer", "_isSnake"]; [_computer, _isSnake] call AE3_armaos_fnc_computer_addGames; },
	[_computer, _isSnake]
] call CBA_fnc_waitUntilAndExecute;

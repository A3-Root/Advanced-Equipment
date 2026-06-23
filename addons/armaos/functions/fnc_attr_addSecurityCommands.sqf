/*
 * Author: Root
 * Description: Eden object-attribute helper. Adds the chosen security commands to a laptop once it
 * has finished initialising, so the attribute can be set in the editor and applied at mission start
 * regardless of init ordering. Server-only; a no-op when neither command is requested.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop object
 * 1: _isCrypto <BOOL> - Add the crypto command
 * 2: _isCrack <BOOL> - Add the crack command
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, true, false] call AE3_armaos_fnc_attr_addSecurityCommands;
 *
 * Public: No
 */

params ["_computer", ["_isCrypto", false], ["_isCrack", false]];

if (!isServer) exitWith {};
if (!_isCrypto && {!_isCrack}) exitWith {};

[
	{ params ["_computer"]; !isNull _computer && {_computer getVariable ["AE3_cap_hasTerminal", false]} },
	{ params ["_computer", "_isCrypto", "_isCrack"]; [_computer, _isCrypto, _isCrack] call AE3_armaos_fnc_computer_addSecurityCommands; },
	[_computer, _isCrypto, _isCrack]
] call CBA_fnc_waitUntilAndExecute;

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Plays a short error sound at the computer when a command fails (wrong usage,
 * command not found, permission denied). Can be disabled via the AE3_EnableErrorSound CBA setting.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer] call AE3_armaos_fnc_shell_playErrorSound;
 *
 * Public: No
 */

params ["_computer"];

if (!(missionNamespace getVariable ["AE3_EnableErrorSound", true])) exitWith {};

playSound3D ["z\ae3\addons\armaos\sounds\Blip.ogg", _computer, false, getPos _computer, 3, 0.7, 20, 0];

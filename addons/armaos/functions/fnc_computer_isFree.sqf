// File: fnc_computer_isFree.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Reports whether a computer can be claimed by a new user. A computer is free when nobody
 * holds its mutex, and also when the holder can no longer be at it: a unit that has died, been deleted
 * (a player who disconnected) or been left behind by a respawn. Without that, a claim taken by a unit
 * that stops existing would keep the laptop locked for the rest of the mission, hiding every interaction
 * on it from everyone.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer to test
 *
 * Return Value:
 * Whether the computer is unclaimed <BOOL>
 *
 * Example:
 * if ([_laptop] call AE3_armaos_fnc_computer_isFree) then { hint "free" };
 *
 * Public: Yes
 */

params [["_computer", objNull, [objNull]]];

if (isNull _computer) exitWith {false};

private _holder = _computer getVariable ["AE3_computer_mutex", objNull];

isNull _holder || {!alive _holder}

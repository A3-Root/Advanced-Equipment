#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Removes a calendar event from a computer's calendar store (AE3_calendar_events) by
 * its index in the synced array. Must run on the server; the trimmed store is re-broadcast.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer to remove the event from
 * 1: _index <NUMBER> - Index of the event in AE3_calendar_events
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [_laptop, 0] call AE3_armaos_fnc_computer_removeCalendarEvent;
 *
 * Public: Yes
 */

params [["_computer", objNull, [objNull]], ["_index", -1, [0]]];

if (!isServer) exitWith { false };
if (isNull _computer) exitWith { false };

private _events = +(_computer getVariable ["AE3_calendar_events", []]);
if (_index < 0 || {_index >= count _events}) exitWith { false };

_events deleteAt _index;
_computer setVariable ["AE3_calendar_events", _events, true];

["ae3_desktop_calChanged", []] call CBA_fnc_globalEvent;

true

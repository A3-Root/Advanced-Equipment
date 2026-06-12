#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Adds a calendar entry to a laptop's /home/user/calendar file (server-side;
 * routed from clients). Entries appear in the Calendar desktop app and can be read with cat.
 * Line format: "DATE | TITLE | DETAILS".
 *
 * Arguments:
 * 0: _target <OBJECT|STRING> - Target laptop, its netId, or "all"
 * 1: _date <STRING> - Date text, e.g. "2035-06-24 04:00"
 * 2: _title <STRING> - Event title
 * 3: _details <STRING> (Optional, default: "") - Event details
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "2035-06-24 04:00", "Convoy departs", "Route Red, 3 trucks"] call AE3_desktop_fnc_addCalendarEvent;
 *
 * Public: Yes
 */

params ["_target", "_date", "_title", ["_details", ""]];

if (!isServer) exitWith
{
	private _targetId = if (_target isEqualType objNull) then { netId _target } else { _target };
	["ae3_desktop_addCalendarEvent", [_targetId, _date, _title, _details]] call CBA_fnc_serverEvent;
};

private _computers = [];
switch (true) do
{
	case (_target isEqualType objNull): { _computers = [_target]; };
	case (_target isEqualTo "all"):     { _computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]); };
	default                             { _computers = [objectFromNetId _target]; };
};

private _line = format ["%1 | %2 | %3%4", _date, _title, _details, endl];

{
	if (!isNull _x && {_x getVariable ["AE3_cap_hasFilesystem", false]}) then
	{
		private _filesystem = _x getVariable ["AE3_filesystem", nil];
		if (!isNil "_filesystem") then
		{
			try
			{
				[[], _filesystem, "/home/user/calendar", "", "root", "root", [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
				[[], _filesystem, "/home/user/calendar", "root", _line, true] call AE3_filesystem_fnc_writeToFile;
			}
			catch
			{
				WARNING_1("Could not add calendar event: %1",_exception);
			};
		};
	};
} forEach _computers;

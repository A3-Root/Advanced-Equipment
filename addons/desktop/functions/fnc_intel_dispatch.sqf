#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Dispatches one intel entry to the matching registry/API. Shared by the Zeus
 * and 3DEN AddIntel module handlers.
 *
 * Types and field meanings:
 *  "email"    - f1: From, f2: Subject, f3: Body
 *  "webpage"  - f1: URL,  f2: Title,   f3: Content ("|" separates lines)
 *  "history"  - f1: URL,  f2: Time (optional, "HH:MM")
 *  "calendar" - f1: Date, f2: Title,   f3: Details
 *  "media"    - f1: Source path, f2: image|video|audio, f3: filesystem destination
 *
 * Arguments:
 * 0: _type <STRING> - See above
 * 1: _target <OBJECT|STRING> - Laptop object, netId, or "all"
 * 2: _f1 <STRING>
 * 3: _f2 <STRING>
 * 4: _f3 <STRING>
 *
 * Return Value:
 * Whether the type was recognized <BOOL>
 *
 * Example:
 * ["email", _laptop, "informant", "Meeting", "Safehouse C4."] call AE3_desktop_fnc_intel_dispatch;
 *
 * Public: Yes
 */

params ["_type", "_target", ["_f1", ""], ["_f2", ""], ["_f3", ""]];

private _known = true;

switch (toLower _type) do
{
	case "email":
	{
		[_target, _f1, _f2, _f3] call AE3_desktop_fnc_addEmail;
	};
	case "webpage":
	{
		[_f1, _f2, _f3 splitString "|"] call AE3_desktop_fnc_registerWebpage;
	};
	case "history":
	{
		[_target, _f1, _f2] call AE3_desktop_fnc_addHistoryEntry;
	};
	case "calendar":
	{
		[_target, _f1, _f2, _f3] call AE3_desktop_fnc_addCalendarEvent;
	};
	case "media":
	{
		private _targets = if (_target isEqualType objNull) then { [_target] } else { _target };
		[_f1, _f2, _f3, _targets] call AE3_desktop_fnc_registerMedia;
	};
	default
	{
		_known = false;
		WARNING_1("Unknown intel type '%1'",_type);
	};
};

_known

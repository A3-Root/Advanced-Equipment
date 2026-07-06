#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Dispatches one intel entry to the matching registry/API. Shared by the Zeus
 * and 3DEN AddIntel module handlers.
 *
 * Types and field meanings:
 *  "email"    - f1: From, f2: To, f3: Subject, f4: Body
 *  "webpage"  - f1: URL,  f2: Title,   f3: Content ("|" separates lines)
 *  "history"  - f1: URL,  f2: Time (optional, "HH:MM")
 *  "media"    - f1: Source path, f2: image|video|audio, f3: filesystem destination,
 *               f4: path scope (mod|mission|auto), f5: try-web-viewer flag <BOOL>
 *  "picture"  - f1: raw base64 image data, f3: filesystem destination
 *  "lockedfile" - f1: filesystem path, f2: password, f3: content, f4: owner, f5: permissions
 *
 * Arguments:
 * 0: _type <STRING> - See above
 * 1: _target <OBJECT|STRING> - Laptop object, netId, or "all"
 * 2: _f1 <STRING>
 * 3: _f2 <STRING>
 * 4: _f3 <STRING>
 * 5: _f4 <STRING> (Optional)
 * 6: _f5 <ARRAY> (Optional)
 *
 * Return Value:
 * Whether the type was recognized <BOOL>
 *
 * Example:
 * ["email", _laptop, "informant", "Meeting", "Safehouse C4."] call AE3_desktop_fnc_intel_dispatch;
 *
 * Public: Yes
 */

params ["_type", "_target", ["_f1", ""], ["_f2", ""], ["_f3", ""], ["_f4", ""], ["_f5", [[true, true, false], [true, false, false]]]];

private _known = true;

switch (toLower _type) do
{
	case "email":
	{
		// Fields are From (f1), To (f2), Subject (f3), Body (f4); an empty body is allowed.
		// f5 from the Zeus dialog carries [receivedTime, createFromHandle, createToHandle].
		private _receivedTime = "";
		private _createFrom = false;
		private _createTo = false;
		if (count _f5 == 3 && {(_f5 select 0) isEqualType ""}) then
		{
			_receivedTime = _f5 select 0;
			_createFrom = (_f5 select 1) isEqualTo true;
			_createTo = (_f5 select 2) isEqualTo true;
		};
		[_target, _f1, _f3, _f4, _f2, _receivedTime, _createFrom, _createTo] call AE3_desktop_fnc_addEmail;
	};
	case "webpage":
	{
		[_f1, _f2, _f3 splitString "|", _target] call AE3_desktop_fnc_registerWebpage;
	};
	case "history":
	{
		[_target, _f1, _f2] call AE3_desktop_fnc_addHistoryEntry;
	};
	case "media":
	{
		private _targets = switch (true) do
		{
			case (_target isEqualType objNull): { [_target] };
			case (_target isEqualType []): { _target };
			case (_target isEqualTo "all"): { "all" };
			case (_target isEqualTo "future"): { "future" };
			default
			{
				private _targetObject = objectFromNetId _target;
				if (isNull _targetObject) then { [] } else { [_targetObject] };
			};
		};
		// f4 carries the mod/mission path hint; f5 the experimental "try web viewer" toggle.
		private _scope = ["auto", _f4] select (_f4 isEqualType "");
		private _web = _f5 isEqualTo true;
		[_f1, _f2, _f3, _targets, _scope, _web] call AE3_desktop_fnc_registerMedia;
	};
	case "picture":
	{
		// Inline base64 image: f1 is the raw base64 payload, f3 the filesystem destination. Stored as
		// a data-URL picture marker rendered by the in-OS web viewer (see fnc_registerPictureB64).
		private _targets = switch (true) do
		{
			case (_target isEqualType objNull): { [_target] };
			case (_target isEqualType []): { _target };
			case (_target isEqualTo "all"): { "all" };
			case (_target isEqualTo "future"): { "future" };
			default
			{
				private _targetObject = objectFromNetId _target;
				if (isNull _targetObject) then { [] } else { [_targetObject] };
			};
		};
		[_f1, _f3, _targets] call AE3_desktop_fnc_registerPictureB64;
	};
	case "lockedfile":
	{
		private _owner = ["root", _f4] select (_f4 isNotEqualTo "");
		[_target, _f1, _f2, _f3, _owner, _f5] call AE3_desktop_fnc_addLockedFile;
	};
	default
	{
		_known = false;
		WARNING_1("Unknown intel type '%1'",_type);
	};
};

_known

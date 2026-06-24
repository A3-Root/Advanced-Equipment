#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers an in-game webpage for the desktop Browser app. Global calls publish
 * a mission-wide page; targeted calls publish the page only on the selected laptop filesystems.
 *
 * Arguments:
 * 0: _url <STRING> - The address, e.g. "intel.root/convoys"
 * 1: _title <STRING> - Page title
 * 2: _content <STRING|ARRAY> - Page text
 * 3: _targets <OBJECT|ARRAY|STRING> (Optional, default: "all") - Laptop targets or "all"
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params ["_url", "_title", "_content", ["_targets", "all"]];

if (!isServer) exitWith
{
	private _targetArg = if (_targets isEqualType objNull) then { netId _targets } else { _targets };
	["ae3_desktop_registerWebpage", [_url, _title, _content, _targetArg]] call CBA_fnc_serverEvent;
};

if (_content isEqualType []) then
{
	_content = _content joinString endl;
};

private _key = toLower _url;
private _entry = [_title, _content];

if (_targets isEqualTo "all") then
{
	private _pages = missionNamespace getVariable ["AE3_Desktop_Webpages", createHashMap];
	_pages set [_key, _entry];
	missionNamespace setVariable ["AE3_Desktop_Webpages", _pages, true];
}
else
{
	private _computers = switch (true) do
	{
		case (_targets isEqualType objNull): { [_targets] };
		case (_targets isEqualType []): { _targets };
		default { [objectFromNetId _targets] };
	};

	{
		if (!isNull _x) then
		{
			private _pages = _x getVariable ["AE3_Desktop_Webpages", createHashMap];
			_pages set [_key, _entry];
			_x setVariable ["AE3_Desktop_Webpages", _pages, true];
		};
	} forEach _computers;
};

INFO_2("Registered webpage %1 (%2)",_url,_title);

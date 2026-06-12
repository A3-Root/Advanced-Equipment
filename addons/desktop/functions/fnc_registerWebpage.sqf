#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers an in-game webpage for the desktop Browser app. Mission makers use
 * this to create lookup-able intel pages (custom URLs). The page registry is a small global
 * hashmap synced once per registration (low frequency). Content supports structured text
 * markup (<t color='#hex'>, <br/> is added automatically per line).
 *
 * Arguments:
 * 0: _url <STRING> - The address, e.g. "intel.root/convoys" (anything players can type)
 * 1: _title <STRING> - Page title
 * 2: _content <STRING|ARRAY> - Page text (string with endl breaks, or array of lines)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["intel.root/convoys", "Convoy Schedule", ["0400 - Route Red", "0600 - Route Blue"]] call AE3_desktop_fnc_registerWebpage;
 *
 * Public: Yes
 */

params ["_url", "_title", "_content"];

if (!isServer) exitWith
{
	["ae3_desktop_registerWebpage", [_url, _title, _content]] call CBA_fnc_serverEvent;
};

if (_content isEqualType []) then
{
	_content = _content joinString endl;
};

private _pages = missionNamespace getVariable ["AE3_Desktop_Webpages", createHashMap];
_pages set [toLower _url, [_title, _content]];

// Small registry, registered rarely (mission setup) - one broadcast per registration is fine
missionNamespace setVariable ["AE3_Desktop_Webpages", _pages, true];

INFO_2("Registered webpage %1 (%2)",_url,_title);

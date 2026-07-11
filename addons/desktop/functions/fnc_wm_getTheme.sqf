// File: fnc_wm_getTheme.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Returns the active theme for a laptop as a hashmap of color arrays. Per-laptop
 * selection (AE3_desktopTheme object variable) overrides the AE3_Desktop_DefaultTheme CBA setting.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 *
 * Return Value:
 * Theme <HASHMAP> with keys: wallpaper, panel, window, titlebar, accent, text
 *
 * Example:
 * private _theme = [_laptop] call AE3_desktop_fnc_wm_getTheme;
 *
 * Public: No
 */

params ["_computer"];

private _themeName = _computer getVariable ["AE3_desktopTheme", missionNamespace getVariable ["AE3_Desktop_DefaultTheme", "Dark"]];

private _cfg = configFile >> "CfgAE3Themes" >> _themeName;
if (!isClass _cfg) then
{
	_cfg = configFile >> "CfgAE3Themes" >> "Dark";
};

private _font = getText (_cfg >> "font");
if (_font isEqualTo "") then { _font = "RobotoCondensed"; };

createHashMapFromArray [
	["name", _themeName],
	["font", _font],
	["wallpaper", getArray (_cfg >> "wallpaperColor")],
	["panel", getArray (_cfg >> "panelColor")],
	["window", getArray (_cfg >> "windowColor")],
	["titlebar", getArray (_cfg >> "titlebarColor")],
	["accent", getArray (_cfg >> "accentColor")],
	["text", getArray (_cfg >> "textColor")]
]

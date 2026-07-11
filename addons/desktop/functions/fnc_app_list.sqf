// File: fnc_app_list.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Returns the merged application registry: CfgAE3Apps config classes plus apps
 * registered at runtime via AE3_desktop_fnc_registerApp.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Apps <ARRAY of [className, displayName, entryFnName, sizeW, sizeH, showOnDesktop, singleton]>
 *
 * Example:
 * private _apps = [] call AE3_desktop_fnc_app_list;
 *
 * Public: Yes
 */

private _apps = [];

{
	private _size = getArray (_x >> "defaultSize");
	_apps pushBack [
		configName _x,
		getText (_x >> "displayName"),
		getText (_x >> "entry"),
		_size param [0, 0.5],
		_size param [1, 0.5],
		(getNumber (_x >> "showOnDesktop")) == 1,
		(getNumber (_x >> "singleton")) == 1
	];
} forEach ("isClass _x" configClasses (configFile >> "CfgAE3Apps"));

// Runtime registered apps
{
	_apps pushBack _x;
} forEach (missionNamespace getVariable ["ae3_desktop_runtimeApps", []]);

_apps

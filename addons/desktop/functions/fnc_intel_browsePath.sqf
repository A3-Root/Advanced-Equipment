#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Opens the shared Zeus filesystem browser as a path picker for the Add Intel dialog.
 * The browser is pointed at the laptop the module is placed on, and the path chosen there is written
 * back into the Add Intel destination field (control 1401). Client-side.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The Add Intel module dialog
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_desktop_fnc_intel_browsePath;
 *
 * Public: No
 */

params ["_display"];

if (isNull _display) exitWith {};

private _computer = _display getVariable ["AE3_linkedComputer", objNull];
if (isNull _computer) exitWith
{
	[localize "STR_AE3_Desktop_Config_AddIntelDisplayName", "Place the module on a laptop to browse its filesystem.", 5] call BIS_fnc_curatorHint;
};

// Hand the browser its target entity and put it in pick mode: the "Select Path" button becomes
// visible and its choice is routed back into the Add Intel destination field.
missionNamespace setVariable ["AE3_zeus_filesystemBrowser_entity", _computer];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickMode", true];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickTarget", [_display, 1401]];

createDialog "AE3_UserInterface_Zeus_FilesystemBrowser";

// File: fnc_intel_browsePath.sqf
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

// The field that holds a laptop filesystem path depends on the intel type: media keeps its
// filesystem save-to path in the third field (1403) while its first field (1401) is the external
// source path; lockedfile keeps its destination in the first field (1401).
private _combo = _display displayCtrl 1702;
private _type = _combo lbData (lbCurSel _combo);
private _pathIdc = [1401, 1403] select (_type isEqualTo "media");

// Hand the browser its target entity and put it in pick mode: the "Select Path" button becomes
// visible and its choice is routed back into the intel destination field.
missionNamespace setVariable ["AE3_zeus_filesystemBrowser_entity", _computer];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickMode", true];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickTarget", [_display, _pathIdc]];

createDialog "AE3_UserInterface_Zeus_FilesystemBrowser";

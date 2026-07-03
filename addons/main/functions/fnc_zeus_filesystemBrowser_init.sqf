/*
 * Author: Root
 * Description: Initializes the Zeus filesystem browser display. Retrieves the entity from mission namespace, loads its filesystem,
 * and sets up the initial display state at the root directory. Closes the dialog if no valid entity is found.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The filesystem browser display
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_main_fnc_zeus_filesystemBrowser_init;
 *
 * Public: No
 */

params ["_display"];

private _entity = missionNamespace getVariable ["AE3_zeus_filesystemBrowser_entity", objNull];
if (isNull _entity) exitWith { closeDialog 0; };

private _pointer = [];

// Store state in display
_display setVariable ["AE3_entity", _entity];
_display setVariable ["AE3_pointer", _pointer];

// The "Select Path" button is only relevant when the browser is opened as a path picker.
(_display displayCtrl 2900) ctrlShow (uiNamespace getVariable ["AE3_zeus_fsBrowser_pickMode", false]);

// On a dedicated server the curator does not hold the entity's filesystem copy. Pull the
// authoritative copy from the server and refresh once it arrives; the first refresh may show an
// empty tree until the transfer completes.
if (isMultiplayer && {isNil {_entity getVariable "AE3_filesystem"}}) then
{
	[_display, _entity] spawn
	{
		params ["_display", "_entity"];
		[_entity, "AE3_filesystem"] call AE3_main_fnc_getRemoteVar;
		if (!isNull _display) then
		{
			[_display] call AE3_main_fnc_zeus_filesystemBrowser_refresh;
		};
	};
};

// Update the file list
[_display] call AE3_main_fnc_zeus_filesystemBrowser_refresh;

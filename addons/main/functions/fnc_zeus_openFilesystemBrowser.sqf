/*
 * Author: Root
 * Description: Opens the filesystem browser dialog for the selected Zeus entity. Allows Zeus curators to browse and manage the filesystem of computers.
 * Validates that the target entity has a filesystem before opening.
 *
 * Arguments:
 * None (uses BIS_fnc_initCuratorAttributes_target from mission namespace)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call AE3_main_fnc_zeus_openFilesystemBrowser;
 *
 * Public: No
 */

private _entity = missionNamespace getVariable ["BIS_fnc_initCuratorAttributes_target", objNull];
if (isNull _entity) exitWith {};

// Identify the device by its AE3_Device config rather than a local AE3_filesystem read: on a
// dedicated server the filesystem lives server-side, so the curator's machine may not hold a copy
// even though the device is fully initialized. The authoritative copy is pulled when the browser
// opens (filesystemBrowser_init).
if (!isClass (configOf _entity >> "AE3_Device")) exitWith
{
	[objNull, localize "STR_AE3_Main_Zeus_NoFilesystem"] call BIS_fnc_showCuratorFeedbackMessage;
};

// Store entity reference for the browser
missionNamespace setVariable ["AE3_zeus_filesystemBrowser_entity", _entity];

// Normal management open - not a path picker.
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickMode", false];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickTarget", nil];

// Open the browser dialog
createDialog "AE3_UserInterface_Zeus_FilesystemBrowser";

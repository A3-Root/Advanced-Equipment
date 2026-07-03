/*
 * Author: Root
 * Description: Confirms the current selection in the Zeus filesystem browser when it is used as a
 * path picker (opened in pick mode by another dialog, e.g. Add Intel). Builds the path from the
 * current directory and any selected item, writes it into the caller's target edit control, clears
 * pick mode and closes the browser.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call AE3_main_fnc_zeus_filesystemBrowser_pickPath;
 *
 * Public: No
 */

private _browser = findDisplay 16993;
if (isNull _browser) exitWith {};

private _pointer = _browser getVariable ["AE3_pointer", []];
private _current = _browser getVariable ["AE3_currentFile", ""];

// A selected file/folder extends the current directory path; otherwise the directory itself is used.
private _parts = +_pointer;
if (_current isNotEqualTo "") then { _parts pushBack _current; };
private _path = "/" + (_parts joinString "/");

private _target = uiNamespace getVariable ["AE3_zeus_fsBrowser_pickTarget", []];
if (count _target isEqualTo 2) then
{
	_target params ["_targetDisplay", "_targetIdc"];
	if (!isNull _targetDisplay) then
	{
		(_targetDisplay displayCtrl _targetIdc) ctrlSetText _path;
	};
};

uiNamespace setVariable ["AE3_zeus_fsBrowser_pickMode", false];
uiNamespace setVariable ["AE3_zeus_fsBrowser_pickTarget", nil];

_browser closeDisplay 0;

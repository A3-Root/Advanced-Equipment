// File: fnc_zeus_filesystemBrowser_refresh.sqf
/*
 * Author: Root
 * Description: Refreshes the Zeus filesystem browser file list. Updates the path display, clears and repopulates the list control
 * with directories and files from the current location. Applies color coding based on item type (directories in blue, executables
 * in green, regular files in white). Clears the file content and properties display areas.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The filesystem browser display
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_main_fnc_zeus_filesystemBrowser_refresh;
 *
 * Public: No
 */

params ["_display"];

private _entity = _display getVariable ["AE3_entity", objNull];
if (isNull _entity) exitWith {};

private _pointer = _display getVariable ["AE3_pointer", []];
private _filesystem = _entity getVariable ["AE3_filesystem", createHashMap];

// Update path display
private _pathCtrl = _display displayCtrl 1400;
private _pathString = "/" + (_pointer joinString "/");
_pathCtrl ctrlSetText _pathString;

// Clear and populate list
private _listCtrl = _display displayCtrl 1500;
lbClear _listCtrl;

// The filesystem is the [content, owner, permissions] triple. On a dedicated server the curator's
// client may not hold it yet (init keeps it server-local and it is fetched asynchronously by
// fnc_zeus_filesystemBrowser_init), so render an empty listing rather than letting resolvePntr fail
// on a missing or partial value; the async fetch triggers another refresh once it arrives.
if (!(_filesystem isEqualType []) || {(count _filesystem) < 1} || {!((_filesystem select 0) isEqualType createHashMap)}) exitWith
{
	(_display displayCtrl 1401) ctrlSetText "";
	(_display displayCtrl 1402) ctrlSetText "";
	(_display displayCtrl 1403) ctrlSetText "";
};

// Get directory object
private _dirObj = [_pointer, _filesystem] call AE3_filesystem_fnc_resolvePntr;
private _dirContent = _dirObj select 0;

// Add parent directory entry if not at root
if (count _pointer > 0) then
{
	private _index = _listCtrl lbAdd "..";
	_listCtrl lbSetData [_index, ".."];
	_listCtrl lbSetColor [_index, [0, 0.55, 0.97, 1]];
};

// List all entries
private _keys = keys _dirContent;
_keys sort true;

{
	private _name = _x;
	private _obj = _dirContent get _name;
	private _isDir = (typeName (_obj select 0)) isEqualTo "HASHMAP";

	private _index = _listCtrl lbAdd _name;
	_listCtrl lbSetData [_index, _name];

	if (_isDir) then
	{
		// Directory - blue color
		_listCtrl lbSetColor [_index, [0, 0.55, 0.97, 1]];
	}
	else
	{
		// File - check if executable
		private _permissions = _obj select 2;
		private _ownerPerms = _permissions select 0;
		private _isExecutable = _ownerPerms select 2;

		if (_isExecutable) then
		{
			// Executable - green color
			_listCtrl lbSetColor [_index, [0.55, 0.88, 0.04, 1]];
		}
		else
		{
			// Regular file - white
			_listCtrl lbSetColor [_index, [1, 1, 1, 1]];
		};
	};
} forEach _keys;

// Do not leave a selection: an RscListBox auto-selects index 0 once populated, which would fire
// onSelect and pre-pick the folder's first item (so "Select Path" returned it without a user click).
_listCtrl lbSetCurSel -1;
_display setVariable ["AE3_currentFile", ""];

// Clear file content and properties
private _contentCtrl = _display displayCtrl 1401;
_contentCtrl ctrlSetText "";

private _ownerCtrl = _display displayCtrl 1402;
_ownerCtrl ctrlSetText "";

private _permCtrl = _display displayCtrl 1403;
_permCtrl ctrlSetText "";

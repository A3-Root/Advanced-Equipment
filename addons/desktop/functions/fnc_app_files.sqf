// File: fnc_app_files.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Files" app: browse the laptop filesystem, open text files and media.
 * Operates on the locally pulled filesystem copy; permission checks use the standard
 * AE3 filesystem functions with the desktop user "root" replaced by the laptop owner model
 * (browsing is gated by the AE3_Desktop_EnableFileBrowsing CBA setting).
 *
 * Arguments:
 * 0: _winId <NUMBER>
 * 1: _ctrlGroup <CONTROL>
 * 2: _computer <OBJECT>
 * 3: _args <ANY>
 *
 * Return Value:
 * App callbacks <HASHMAP>
 *
 * Public: No
 */

params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];

if (!(missionNamespace getVariable ["AE3_Desktop_EnableFileBrowsing", true])) exitWith
{
	private _note = _display ctrlCreate ["RscText", -1, _ctrlGroup];
	_note ctrlSetPosition [0.01, 0.05, 0.5, 0.04];
	_note ctrlSetText (localize "STR_AE3_Desktop_Files_Disabled");
	_note ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
	_note ctrlCommit 0;
	createHashMap
};

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

/* path label */
private _pathCtrl = _display ctrlCreate ["RscText", -1, _ctrlGroup];
_pathCtrl ctrlSetPosition [0.01, 0.045, _w - 0.07, 0.035];
_pathCtrl ctrlSetTextColor (_theme getOrDefault ["accent", [1,1,1,1]]);
_pathCtrl ctrlCommit 0;

/* up button */
private _upBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_upBtn ctrlSetPosition [_w - 0.06, 0.045, 0.05, 0.035];
_upBtn ctrlSetText "..";
_upBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_upBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_upBtn ctrlCommit 0;

/* listing */
private _listCtrl = _display ctrlCreate ["RscListBox", -1, _ctrlGroup];
_listCtrl ctrlSetPosition [0.01, 0.085, _w - 0.02, _h - 0.095];
_listCtrl ctrlCommit 0;

/* ---------------------------------------- */
/* state + refresh logic stored on the list control */

_listCtrl setVariable ["AE3_computer", _computer];
_listCtrl setVariable ["AE3_path", + (_args param [0, []])]; // restored session path, if any
_listCtrl setVariable ["AE3_pathCtrl", _pathCtrl];

private _refresh = {
	params ["_listCtrl"];

	private _computer = _listCtrl getVariable "AE3_computer";
	private _path = _listCtrl getVariable "AE3_path";
	private _pathCtrl = _listCtrl getVariable "AE3_pathCtrl";

	lbClear _listCtrl;
	_pathCtrl ctrlSetText ("/" + (_path joinString "/"));

	private _filesystem = _computer getVariable ["AE3_filesystem", []];
	if (_filesystem isEqualTo []) exitWith {};

	// Resolve the current directory in the local filesystem copy
	private _current = _filesystem;
	{
		private _content = _current select 0;
		if (!(_x in _content)) exitWith { _current = []; };
		_current = _content get _x;
	} forEach _path;
	if (_current isEqualTo []) exitWith {};

	private _content = _current select 0;
	private _names = keys _content;
	_names sort true;

	{
		private _obj = _content get _x;
		private _isDir = (_obj select 0) isEqualType createHashMap;
		private _index = _listCtrl lbAdd _x;
		_listCtrl lbSetData [_index, _x];
		if (_isDir) then
		{
			_listCtrl lbSetColor [_index, [0, 0.55, 0.97, 1]];
			_listCtrl lbSetPicture [_index, "\z\ae3\addons\filesystem\ui\AE3_Module_Icons_addDir.paa"];
		}
		else
		{
			// Executable files (code payload) are tinted green and run on double-click, like an .app.
			if ((_obj select 0) isEqualType {}) then
			{
				_listCtrl lbSetColor [_index, [0.3, 0.85, 0.4, 1]];
			};
			_listCtrl lbSetPicture [_index, "\z\ae3\addons\filesystem\ui\AE3_Module_Icons_addFile.paa"];
		};
	} forEach _names;
};

_listCtrl setVariable ["AE3_refresh", _refresh];
[_listCtrl] call _refresh;

/* ---------------------------------------- */

_upBtn setVariable ["AE3_listCtrl", _listCtrl];
_upBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _listCtrl = _button getVariable "AE3_listCtrl";
	private _path = _listCtrl getVariable "AE3_path";
	if (_path isNotEqualTo []) then { _path deleteAt (count _path - 1); };
	_listCtrl setVariable ["AE3_path", _path];
	[_listCtrl] call (_listCtrl getVariable "AE3_refresh");
}];

_listCtrl ctrlAddEventHandler ["LBDblClick", {
	params ["_listCtrl", "_index"];

	private _computer = _listCtrl getVariable "AE3_computer";
	private _path = _listCtrl getVariable "AE3_path";
	private _name = _listCtrl lbData _index;

	private _filesystem = _computer getVariable ["AE3_filesystem", []];
	private _current = _filesystem;
	{
		_current = (_current select 0) get _x;
	} forEach _path;

	private _obj = (_current select 0) getOrDefault [_name, []];
	if (_obj isEqualTo []) exitWith {};

	if ((_obj select 0) isEqualType createHashMap) then
	{
		// directory - enter
		_path pushBack _name;
		_listCtrl setVariable ["AE3_path", _path];
		[_listCtrl] call (_listCtrl getVariable "AE3_refresh");
	}
	else
	{
		// file - locked files prompt for a password, text files open in Notepad (editable),
		// everything else via the dispatcher
		private _fullPath = "/" + ((_path + [_name]) joinString "/");
		private _content = _obj select 0;

		(([_content] call AE3_armaos_fnc_shell_parseLockedFile)) params ["_isLocked", "_filePassword", "_payload"];

		switch (true) do
		{
			case (_isLocked):
			{
				[_computer, _fullPath, _filePassword, _payload] call AE3_desktop_fnc_promptUnlock;
			};
			case (_content isEqualType "" && {(_content select [0, 10]) isNotEqualTo "AE3_MEDIA|"}):
			{
				["Notepad", [_fullPath]] call AE3_desktop_fnc_wm_createWindow;
			};
			default
			{
				[_computer, _fullPath, _content] call AE3_desktop_fnc_openFile;
			};
		};
	};
}];

createHashMapFromArray [
	["listCtrl", _listCtrl],
	["getState", {
		private _ctrl = _this getOrDefault ["listCtrl", controlNull];
		if (isNull _ctrl) exitWith { [] };
		[+ (_ctrl getVariable ["AE3_path", []])]
	}]
]

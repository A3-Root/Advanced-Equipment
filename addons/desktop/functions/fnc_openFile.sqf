#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Opens a filesystem entry in the matching desktop viewer: media markers
 * ("AE3_MEDIA|<type>|<source path>") open the image viewer / video player / audio player,
 * plain text opens the text viewer, executables show a notice (run them in the Terminal app).
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 * 1: _path <STRING> - Virtual filesystem path (for the window title)
 * 2: _content <STRING|CODE> - File content
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "/home/user/notes.txt", "hello"] call AE3_desktop_fnc_openFile;
 *
 * Public: Yes
 */

params ["_computer", "_path", "_content"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];
if (isNull _display) then {
	private _webCtrl = uiNamespace getVariable [QGVAR(browserCtrl), controlNull];
	if (!isNull _webCtrl) then {
		_display = ctrlParent _webCtrl;
		_theme = createHashMap;
	};
};
if (isNull _display) exitWith {};

// Executables can only be run from the terminal
if (_content isEqualType {}) exitWith
{
	hintSilent (localize "STR_AE3_Desktop_Files_Executable");
};

if (!(_content isEqualType "")) exitWith {};

/* ---------------------------------------- */
/* Media marker files */

if ((_content select [0, 10]) isEqualTo "AE3_MEDIA|") exitWith
{
	(_content splitString "|") params ["", "_type", "_sourcePath"];

	switch (toLower _type) do
	{
		case "image":
		{
			// dedicated image window
			private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
			_group ctrlSetPosition [safeZoneX + 0.25, safeZoneY + 0.1, 0.45, 0.55];
			_group ctrlCommit 0;

			private _body = _display ctrlCreate ["RscText", -1, _group];
			_body ctrlSetPosition [0, 0, 0.45, 0.55];
			_body ctrlSetBackgroundColor (_theme getOrDefault ["window", [0,0,0,1]]);
			_body ctrlCommit 0;

			private _pic = _display ctrlCreate ["RscPicture", -1, _group];
			_pic ctrlSetPosition [0.01, 0.05, 0.43, 0.45];
			_pic ctrlSetText _sourcePath;
			_pic ctrlCommit 0;

			private _closeBtn = _display ctrlCreate ["RscButton", -1, _group];
			_closeBtn ctrlSetPosition [0.40, 0, 0.05, 0.04];
			_closeBtn ctrlSetText "X";
			_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
			_closeBtn ctrlCommit 0;
			_closeBtn setVariable ["AE3_group", _group];
			_closeBtn ctrlAddEventHandler ["ButtonClick", { ctrlDelete ((_this select 0) getVariable "AE3_group"); }];
		};
		case "video":
		{
			[_sourcePath] call BIS_fnc_playVideo;
		};
		case "audio":
		{
			playSound3D [_sourcePath, player, false, getPosASL player, 5, 1, 30, 0];
			hintSilent (localize "STR_AE3_Desktop_Media_Playing");
		};
		default
		{
			hintSilent format [localize "STR_AE3_Desktop_Media_Unknown", _type];
		};
	};
};

/* ---------------------------------------- */
/* Plain text viewer */

private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_group ctrlSetPosition [safeZoneX + 0.22, safeZoneY + 0.08, 0.5, 0.6];
_group ctrlCommit 0;

private _body = _display ctrlCreate ["RscText", -1, _group];
_body ctrlSetPosition [0, 0, 0.5, 0.6];
_body ctrlSetBackgroundColor (_theme getOrDefault ["window", [0,0,0,1]]);
_body ctrlCommit 0;

private _title = _display ctrlCreate ["RscText", -1, _group];
_title ctrlSetPosition [0, 0, 0.45, 0.04];
_title ctrlSetText _path;
_title ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_title ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_title ctrlCommit 0;

private _text = _display ctrlCreate ["RscStructuredText", -1, _group];
_text ctrlSetPosition [0.01, 0.05, 0.48, 0.54];
_text ctrlSetStructuredText (parseText ((_content splitString endl) joinString "<br/>"));
_text ctrlCommit 0;

private _closeBtn = _display ctrlCreate ["RscButton", -1, _group];
_closeBtn ctrlSetPosition [0.45, 0, 0.05, 0.04];
_closeBtn ctrlSetText "X";
_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
_closeBtn ctrlCommit 0;
_closeBtn setVariable ["AE3_group", _group];
_closeBtn ctrlAddEventHandler ["ButtonClick", { ctrlDelete ((_this select 0) getVariable "AE3_group"); }];

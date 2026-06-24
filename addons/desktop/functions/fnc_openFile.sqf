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
	([_content] call AE3_desktop_fnc_parseMediaMarker) params ["", "_type", "", "", "_sourcePath"];
	if (AE3_DebugMode) then { diag_log format ["[AE3 DEBUG] [%1] openFile native viewer: type=%2 src=%3", time, _type, _sourcePath]; };

	switch (_type) do
	{
		case "image":
		{
			// Native image viewer used as the fallback when the in-OS web viewer cannot display the
			// source. The picture renders through the engine texture loader (which reliably handles
			// mission and mod .jpg/.paa), in a child display of the desktop so it sits ON TOP of the
			// web surface, with a Close button (and Esc) to dismiss it.
			private _imgDisplay = _display createDisplay "RscDisplayEmpty";

			if (isNull _imgDisplay) then
			{
				// No child display available: fall back to an overlay on the desktop display itself.
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
			}
			else
			{
				private _bg = _imgDisplay ctrlCreate ["RscText", -1];
				_bg ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
				_bg ctrlSetBackgroundColor [0, 0, 0, 0.85];
				_bg ctrlCommit 0;

				private _pic = _imgDisplay ctrlCreate ["RscPicture", -1];
				_pic ctrlSetPosition [safeZoneX + 0.10 * safeZoneW, safeZoneY + 0.08 * safeZoneH, 0.80 * safeZoneW, 0.84 * safeZoneH];
				_pic ctrlSetText _sourcePath;
				_pic ctrlCommit 0;

				private _closeBtn = _imgDisplay ctrlCreate ["RscButton", -1];
				_closeBtn ctrlSetPosition [safeZoneX + safeZoneW - 0.13, safeZoneY + 0.02, 0.11, 0.05];
				_closeBtn ctrlSetText (localize "STR_AE3_Desktop_Media_Close");
				_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
				_closeBtn ctrlCommit 0;
				_closeBtn ctrlAddEventHandler ["ButtonClick", { (ctrlParent (_this select 0)) closeDisplay 2; }];

				// Esc closes the viewer too.
				_imgDisplay displayAddEventHandler ["KeyDown", {
					params ["_disp", "_key"];
					if (_key isEqualTo 1) then { _disp closeDisplay 2; true } else { false }
				}];
			};
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

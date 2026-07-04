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
 * 3: _rect <ARRAY> (Optional, default: []) - [x, y, w, h] as viewport fractions of the in-OS window
 *    that requested the open, used to position the native image viewer to overlay it
 * 4: _options <HASHMAP> (Optional, default: empty) - Media playback options
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "/home/user/notes.txt", "hello"] call AE3_desktop_fnc_openFile;
 *
 * Public: Yes
 */

params ["_computer", "_path", "_content", ["_rect", []], ["_options", createHashMap]];
if !(_options isEqualType createHashMap) then { _options = createHashMap; };

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
	([_content] call AE3_desktop_fnc_parseMediaMarker) params ["", "_type", "_scope", "", "_sourcePath"];
	if (AE3_DebugMode) then { diag_log format ["[AE3 DEBUG] [%1] openFile native viewer: type=%2 scope=%3 src=%4", time, _type, _scope, _sourcePath]; };

	switch (_type) do
	{
		case "image":
		{
			[_computer, "image", _sourcePath, _path, true] call AE3_desktop_fnc_mediaNotify;
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
				_closeBtn setVariable ["AE3_media", [_computer, "image", _sourcePath, _path]];
				_closeBtn ctrlAddEventHandler ["ButtonClick", {
					((_this select 0) getVariable ["AE3_media", []]) params [["_c", objNull], ["_t", ""], ["_s", ""], ["_v", ""]];
					if (!isNull _c) then { [_c, _t, _s, _v, false] call AE3_desktop_fnc_mediaNotify; };
					ctrlDelete ((_this select 0) getVariable "AE3_group");
				}];
			}
			else
			{
				// Window-sized panel (not full-screen) with a title bar. When the caller passed the
				// footprint of the in-OS Image Viewer window (viewport fractions), map it onto the web
				// surface's on-screen rectangle so the native viewer overlays that window exactly;
				// otherwise fall back to a centred panel. A dim backdrop catches stray clicks.
				private _barH = 0.045;
				private _x = 0;
				private _y = 0;
				private _w = 0.5;
				private _h = 0.6;
				if (_rect isEqualType [] && {count _rect >= 4} && {(_rect select 2) > 0} && {(_rect select 3) > 0}) then
				{
					private _wc = uiNamespace getVariable [QGVAR(browserCtrl), controlNull];
					private _cp = if (isNull _wc) then { [safeZoneX, safeZoneY, safeZoneW, safeZoneH] } else { ctrlPosition _wc };
					_cp params ["_cpx", "_cpy", "_cpw", "_cph"];
					_x = _cpx + (_rect select 0) * _cpw;
					_y = _cpy + (_rect select 1) * _cph;
					_w = (_rect select 2) * _cpw;
					_h = (_rect select 3) * _cph;
				}
				else
				{
					_x = safeZoneX + (safeZoneW - _w) / 2;
					_y = safeZoneY + (safeZoneH - _h) / 2;
				};

				private _backdrop = _imgDisplay ctrlCreate ["RscText", -1];
				_backdrop ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
				_backdrop ctrlSetBackgroundColor [0, 0, 0, 0.6];
				_backdrop ctrlCommit 0;

				private _panel = _imgDisplay ctrlCreate ["RscText", -1];
				_panel ctrlSetPosition [_x, _y, _w, _h];
				_panel ctrlSetBackgroundColor (_theme getOrDefault ["window", [0.1, 0.1, 0.1, 1]]);
				_panel ctrlCommit 0;

				private _title = _imgDisplay ctrlCreate ["RscText", -1];
				_title ctrlSetPosition [_x, _y, _w - _barH, _barH];
				_title ctrlSetText _path;
				_title ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0.15, 0.15, 0.15, 1]]);
				_title ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
				_title ctrlCommit 0;

				private _closeBtn = _imgDisplay ctrlCreate ["RscButton", -1];
				_closeBtn ctrlSetPosition [_x + _w - _barH, _y, _barH, _barH];
				_closeBtn ctrlSetText "X";
				_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
				_closeBtn ctrlCommit 0;
				_closeBtn ctrlAddEventHandler ["ButtonClick", { (ctrlParent (_this select 0)) closeDisplay 2; }];

				private _pic = _imgDisplay ctrlCreate ["RscPictureKeepAspect", -1];
				_pic ctrlSetPosition [_x + 0.006, _y + _barH + 0.006, _w - 0.012, _h - _barH - 0.012];
				_pic ctrlSetText _sourcePath;
				_pic ctrlCommit 0;

				// Esc closes the viewer too.
				_imgDisplay displayAddEventHandler ["KeyDown", {
					params ["_disp", "_key"];
					if (_key isEqualTo 1) then { _disp closeDisplay 2; true } else { false }
				}];

				// Report the close once, however it was dismissed (button, Esc or otherwise).
				_imgDisplay setVariable ["AE3_media", [_computer, "image", _sourcePath, _path]];
				_imgDisplay displayAddEventHandler ["Unload", {
					params ["_disp"];
					(_disp getVariable ["AE3_media", []]) params [["_c", objNull], ["_t", ""], ["_s", ""], ["_v", ""]];
					if (!isNull _c) then { [_c, _t, _s, _v, false] call AE3_desktop_fnc_mediaNotify; };
				}];
			};
		};
		case "video":
		{
			[_computer, "video", _sourcePath, _path, true] call AE3_desktop_fnc_mediaNotify;
			// BIS_fnc_playVideo renders on its own display, which sits behind the web surface. The
			// browser is hidden while the video is active and restored when playback finishes.
			private _webCtrl = uiNamespace getVariable [QGVAR(browserCtrl), controlNull];
			if (!isNull _webCtrl) then { _webCtrl ctrlShow false; };

			private _allowStop = _options getOrDefault ["allowStop", true];
			private _volumeScale = (_options getOrDefault ["volume", 1]) max 0;
			private _oldSoundVolume = soundVolume;
			private _oldMusicVolume = musicVolume;
			if (_volumeScale isNotEqualTo 1) then {
				0 fadeSound (_oldSoundVolume * _volumeScale);
				0 fadeMusic (_oldMusicVolume * _volumeScale);
			};

			private _skipVar = format ["AE3_desktop_skipVideo_%1", round (diag_tickTime * 1000)];
			missionNamespace setVariable [_skipVar, false];
			private _vid = [_sourcePath, [safeZoneX, safeZoneY, safeZoneW, safeZoneH], [1, 1, 1, 1], _skipVar] spawn BIS_fnc_playVideo;

			private _ctl = _display createDisplay "RscDisplayEmpty";
			if (!isNull _ctl) then
			{
				_ctl setVariable ["AE3_skipVar", _skipVar];
				if (_allowStop) then {
					private _stop = _ctl ctrlCreate ["RscButton", -1];
					_stop ctrlSetPosition [safeZoneX + safeZoneW - 0.17, safeZoneY + 0.03, 0.15, 0.05];
					_stop ctrlSetText (localize "STR_AE3_Desktop_Media_Stop");
					_stop ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
					_stop ctrlCommit 0;
					_stop setVariable ["AE3_skipVar", _skipVar];
					_stop ctrlAddEventHandler ["ButtonClick", { missionNamespace setVariable [(_this select 0) getVariable "AE3_skipVar", true]; }];
				};
				_ctl displayAddEventHandler ["KeyDown", {
					params ["_disp", "_key"];
					private _skip = _disp getVariable ["AE3_allowSkip", true];
					if (_key isEqualTo 1) then {
						if (_skip) then { missionNamespace setVariable [_disp getVariable "AE3_skipVar", true]; };
						true
					} else { !_skip }
				}];
				_ctl setVariable ["AE3_allowSkip", _allowStop];
			};

			[_vid, _webCtrl, _ctl, _skipVar, _computer, _sourcePath, _path, _volumeScale, _oldSoundVolume, _oldMusicVolume] spawn
			{
				params ["_vid", "_webCtrl", "_ctl", "_skipVar", "_computer", "_sourcePath", "_path", "_volumeScale", "_oldSoundVolume", "_oldMusicVolume"];
				waitUntil { scriptDone _vid };
				if (!isNull _ctl) then { _ctl closeDisplay 2; };
				if (!isNull _webCtrl) then { _webCtrl ctrlShow true; };
				if (_volumeScale isNotEqualTo 1) then {
					0 fadeSound _oldSoundVolume;
					0 fadeMusic _oldMusicVolume;
				};
				missionNamespace setVariable [_skipVar, nil];
				[_computer, "video", _sourcePath, _path, false] call AE3_desktop_fnc_mediaNotify;
			};
		};
		case "audio":
		{
			[_computer, _sourcePath, _scope, _path] call AE3_desktop_fnc_audioPlayer;
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

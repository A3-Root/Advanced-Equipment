#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Opens a small native audio player for a registered audio file. The player is a child
 * display of the desktop (rendered above the web surface) with a seekable progress bar, an elapsed/
 * total time readout and a Stop button (Esc also stops). The clip is played LOCALLY (playSound3D with
 * the local flag) so only the player using the laptop hears it and its sound id can be stopped client-
 * side. The seek bar and time are driven by soundParams (current position and total length); clicking
 * the bar restarts playback from that offset, and the player auto-closes when the clip ends.
 *
 * Arguments:
 * 0: _emitter <OBJECT> - Sound emitter (the laptop)
 * 1: _sourcePath <STRING> - Raw media source path
 * 2: _scope <STRING> (Optional, default "auto") - "mod" | "mission" | "auto"
 * 3: _title <STRING> (Optional, default "") - Display name
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_emitter", "_sourcePath", ["_scope", "auto"], ["_title", ""]];

if (!hasInterface) exitWith {};

// Mission-folder audio is addressed via its absolute on-disk path; mod/absolute paths are used as-is.
private _abs = if (_scope isEqualTo "mod" || {(_sourcePath select [0, 1]) isEqualTo "\"}) then { _sourcePath } else { getMissionPath _sourcePath };
private _src = if (isNull _emitter) then { player } else { _emitter };

// Local-only positional playback; returns a client-local sound id used for stop/seek.
private _play = {
	params ["_abs", "_src", "_offset"];
	playSound3D [_abs, _src, false, getPosASL _src, 5, 1, 30, _offset, true]
};

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];
if (isNull _display) then
{
	private _webCtrl = uiNamespace getVariable [QGVAR(browserCtrl), controlNull];
	if (!isNull _webCtrl) then { _display = ctrlParent _webCtrl; };
};

// No desktop display available: play with no controls.
if (isNull _display) exitWith { [_abs, _src, 0] call _play; };

private _ov = _display createDisplay "RscDisplayEmpty";
if (isNull _ov) exitWith { [_abs, _src, 0] call _play; };

private _w = 0.42;
private _h = 0.16;
private _x = safeZoneX + (safeZoneW - _w) / 2;
private _y = safeZoneY + (safeZoneH - _h) / 2;

private _bg = _ov ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.55];
_bg ctrlCommit 0;

private _panel = _ov ctrlCreate ["RscText", -1];
_panel ctrlSetPosition [_x, _y, _w, _h];
_panel ctrlSetBackgroundColor (_theme getOrDefault ["window", [0.1, 0.1, 0.1, 1]]);
_panel ctrlCommit 0;

private _titleCtrl = _ov ctrlCreate ["RscText", -1];
_titleCtrl ctrlSetPosition [_x + 0.012, _y + 0.01, _w - 0.024, 0.035];
_titleCtrl ctrlSetText _title;
_titleCtrl ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
_titleCtrl ctrlCommit 0;

private _trackX = _x + 0.02;
private _trackY = _y + 0.065;
private _trackW = _w - 0.04;
private _trackH = 0.016;

private _track = _ov ctrlCreate ["RscText", -1];
_track ctrlSetPosition [_trackX, _trackY, _trackW, _trackH];
_track ctrlSetBackgroundColor [0.25, 0.25, 0.25, 1];
_track ctrlCommit 0;

private _fill = _ov ctrlCreate ["RscText", -1];
_fill ctrlSetPosition [_trackX, _trackY, 0, _trackH];
_fill ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
_fill ctrlCommit 0;

// Transparent button over the track captures the seek click.
private _seek = _ov ctrlCreate ["RscButton", -1];
_seek ctrlSetPosition [_trackX, _trackY - 0.012, _trackW, _trackH + 0.024];
_seek ctrlSetText "";
_seek ctrlSetBackgroundColor [0, 0, 0, 0];
_seek ctrlCommit 0;

private _timeCtrl = _ov ctrlCreate ["RscText", -1];
_timeCtrl ctrlSetPosition [_trackX, _trackY + 0.026, _trackW - 0.12, 0.03];
_timeCtrl ctrlSetText "0:00";
_timeCtrl ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
_timeCtrl ctrlCommit 0;

private _stop = _ov ctrlCreate ["RscButton", -1];
_stop ctrlSetPosition [_x + _w - 0.115, _y + _h - 0.05, 0.10, 0.04];
_stop ctrlSetText (localize "STR_AE3_Desktop_Media_Stop");
_stop ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
_stop ctrlCommit 0;

private _id = [_abs, _src, 0] call _play;

_ov setVariable ["soundId", _id];
_ov setVariable ["abs", _abs];
_ov setVariable ["src", _src];
_ov setVariable ["fill", _fill];
_ov setVariable ["timeCtrl", _timeCtrl];
_ov setVariable ["trackGeom", [_trackX, _trackY, _trackW, _trackH]];
_ov setVariable ["media", [_emitter, "audio", _sourcePath, _title]];

[_emitter, "audio", _sourcePath, _title, true] call AE3_desktop_fnc_mediaNotify;

// Stop + tidy up (button, Esc, and the natural end of the clip all route here).
private _fnStop = {
	params ["_ov"];
	if (isNull _ov) exitWith {};
	private _pfh = _ov getVariable ["pfh", -1];
	if (_pfh != -1) then { _pfh call CBA_fnc_removePerFrameHandler; };
	private _id = _ov getVariable ["soundId", -1];
	if (_id != -1) then { stopSound _id; };
	(_ov getVariable ["media", []]) params [["_c", objNull], ["_t", ""], ["_s", ""], ["_v", ""]];
	if (!isNull _c) then { [_c, _t, _s, _v, false] call AE3_desktop_fnc_mediaNotify; };
	_ov closeDisplay 2;
};
_ov setVariable ["fnStop", _fnStop];

_seek setVariable ["ov", _ov];
_seek ctrlAddEventHandler ["MouseButtonDown", {
	params ["_ctrl", "_button", "_xPos"];
	if (_button != 0) exitWith {};
	private _ov = _ctrl getVariable "ov";
	private _id = _ov getVariable ["soundId", -1];
	private _params = if (_id isEqualTo -1) then { [] } else { soundParams _id };
	if (_params isEqualTo []) exitWith {};
	private _length = _params select 2;
	(_ov getVariable "trackGeom") params ["_tx", "", "_tw"];
	private _frac = (((_xPos - _tx) / _tw) max 0) min 1;
	if (_id != -1) then { stopSound _id; };
	private _src = _ov getVariable "src";
	private _newId = playSound3D [_ov getVariable "abs", _src, false, getPosASL _src, 5, 1, 30, _frac * _length, true];
	_ov setVariable ["soundId", _newId];
}];

_stop setVariable ["ov", _ov];
_stop ctrlAddEventHandler ["ButtonClick", { private _ov = (_this select 0) getVariable "ov"; [_ov] call (_ov getVariable "fnStop"); }];

_ov displayAddEventHandler ["KeyDown", {
	params ["_disp", "_key"];
	if (_key isEqualTo 1) then { [_disp] call (_disp getVariable "fnStop"); true } else { false }
}];

private _fmtTime = {
	params ["_s"];
	format ["%1:%2", floor (_s / 60), [floor (_s mod 60), 2] call CBA_fnc_formatNumber]
};

private _pfh = [{
	params ["_args", "_handle"];
	_args params ["_ov", "_fmtTime"];
	if (isNull _ov) exitWith { _handle call CBA_fnc_removePerFrameHandler; };

	private _id = _ov getVariable ["soundId", -1];
	private _params = if (_id isEqualTo -1) then { [] } else { soundParams _id };
	// An empty result means the clip finished playing.
	if (_params isEqualTo []) exitWith { [_ov] call (_ov getVariable "fnStop"); };

	_params params ["", "_curPos", "_length"];
	(_ov getVariable "trackGeom") params ["_tx", "_ty", "_tw", "_th"];
	(_ov getVariable "fill") ctrlSetPosition [_tx, _ty, _tw * _curPos, _th];
	(_ov getVariable "fill") ctrlCommit 0;
	(_ov getVariable "timeCtrl") ctrlSetText format ["%1 / %2", [_curPos * _length] call _fmtTime, [_length] call _fmtTime];
}, 0.1, [_ov, _fmtTime]] call CBA_fnc_addPerFrameHandler;
_ov setVariable ["pfh", _pfh];

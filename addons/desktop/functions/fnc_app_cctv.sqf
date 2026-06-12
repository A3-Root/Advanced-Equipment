#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "CCTV" app: cycles through cameras registered with
 * AE3_desktop_fnc_registerCamera. The feed is a local render-to-texture camera on the
 * viewing client only - no network traffic. The camera is destroyed when the window closes.
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

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

private _cameras = missionNamespace getVariable ["AE3_Desktop_Cameras", []];
// drop cameras whose object was deleted
_cameras = _cameras select { !isNull (_x select 1) };

/* feed area */
private _feedCtrl = _display ctrlCreate ["RscPicture", -1, _ctrlGroup];
_feedCtrl ctrlSetPosition [0.01, 0.085, _w - 0.02, _h - 0.10];
_feedCtrl ctrlCommit 0;

/* name + prev/next */
private _nameCtrl = _display ctrlCreate ["RscText", -1, _ctrlGroup];
_nameCtrl ctrlSetPosition [0.07, 0.045, _w - 0.14, 0.035];
_nameCtrl ctrlSetTextColor (_theme getOrDefault ["accent", [1,1,1,1]]);
_nameCtrl ctrlCommit 0;

private _prevBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_prevBtn ctrlSetPosition [0.01, 0.045, 0.05, 0.035];
_prevBtn ctrlSetText "<";
_prevBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_prevBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_prevBtn ctrlCommit 0;

private _nextBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_nextBtn ctrlSetPosition [_w - 0.06, 0.045, 0.05, 0.035];
_nextBtn ctrlSetText ">";
_nextBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_nextBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_nextBtn ctrlCommit 0;

/* ---------------------------------------- */

if (_cameras isEqualTo []) exitWith
{
	_nameCtrl ctrlSetText (localize "STR_AE3_Desktop_Cctv_NoCameras");
	createHashMap
};

// One local r2t camera, re-pointed when switching feeds (app is a singleton)
private _cam = "camera" camCreate [0, 0, 0];
_cam cameraEffect ["Internal", "Back", "ae3cctv"];
_feedCtrl ctrlSetText "#(argb,512,512,1)r2t(ae3cctv,1.0)";
uiNamespace setVariable ["AE3_desktop_cctvCam", _cam];

_nameCtrl setVariable ["AE3_ctx", [_cam, _cameras, 0, _nameCtrl]];

private _switchTo = {
	params ["_nameCtrl", "_step"];

	(_nameCtrl getVariable "AE3_ctx") params ["_cam", "_cameras", "_index"];
	_index = (_index + _step + count _cameras) mod (count _cameras);
	(_cameras select _index) params ["_name", "_object", "_offset", "_dir"];

	if (isNull _object) exitWith { _nameCtrl ctrlSetText (localize "STR_AE3_Desktop_Cctv_NoCameras"); };

	private _pos = _object modelToWorld _offset;
	_cam setPosATL _pos;
	_cam setDir _dir;
	_cam setVectorUp [0, 0, 1];
	_cam camCommit 0;

	_nameCtrl ctrlSetText format ["%1 (%2/%3)", _name, _index + 1, count _cameras];
	_nameCtrl setVariable ["AE3_ctx", [_cam, _cameras, _index, _nameCtrl]];
};

_nameCtrl setVariable ["AE3_switchTo", _switchTo];
[_nameCtrl, 0] call _switchTo;

_prevBtn setVariable ["AE3_nameCtrl", _nameCtrl];
_prevBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _nameCtrl = _button getVariable "AE3_nameCtrl";
	[_nameCtrl, -1] call (_nameCtrl getVariable "AE3_switchTo");
}];

_nextBtn setVariable ["AE3_nameCtrl", _nameCtrl];
_nextBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _nameCtrl = _button getVariable "AE3_nameCtrl";
	[_nameCtrl, 1] call (_nameCtrl getVariable "AE3_switchTo");
}];

// camera must be destroyed when the window (or the whole desktop) closes
createHashMapFromArray [
	["onClose", {
		private _cam = uiNamespace getVariable ["AE3_desktop_cctvCam", objNull];
		if (!isNull _cam) then
		{
			_cam cameraEffect ["Terminate", "Back", "ae3cctv"];
			camDestroy _cam;
		};
		uiNamespace setVariable ["AE3_desktop_cctvCam", nil];
	}]
]

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a CCTV camera for the desktop "CCTV" app. The camera is attached to
 * (or placed at) the given object and rendered into the app via render-to-texture on the
 * viewing client only. The registry is a small global list synced once per registration.
 *
 * Arguments:
 * 0: _name <STRING> - Camera name shown in the app
 * 1: _object <OBJECT> - Object the camera view originates from (e.g. a placed CCTV prop)
 * 2: _offset <ARRAY> (Optional, default: [0, 0.2, 0.1]) - Model-space position offset
 * 3: _dir <NUMBER> (Optional, default: object direction) - View direction in degrees
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Compound Gate", _cctvProp] call AE3_desktop_fnc_registerCamera;
 *
 * Public: Yes
 */

params ["_name", "_object", ["_offset", [0, 0.2, 0.1]], ["_dir", -1]];

if (isNull _object) exitWith {};

if (!isServer) exitWith
{
	["ae3_desktop_registerCamera", [_name, _object, _offset, _dir]] call CBA_fnc_serverEvent;
};

if (_dir < 0) then { _dir = getDir _object; };

private _cameras = missionNamespace getVariable ["AE3_Desktop_Cameras", []];
_cameras pushBack [_name, _object, _offset, _dir];

// Small registry, registered rarely (mission setup) - one broadcast per registration is fine
missionNamespace setVariable ["AE3_Desktop_Cameras", _cameras, true];

INFO_1("Registered CCTV camera '%1'",_name);

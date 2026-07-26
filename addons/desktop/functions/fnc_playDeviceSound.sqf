// File: fnc_playDeviceSound.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Plays a positional device sound on each connected client. The engine applies the
 *              requested distance locally, keeping the sound audible only near its source.
 *
 * Arguments:
 * 0: _device <OBJECT> - Object that emits the sound
 * 1: _path <STRING> - Addon-relative sound path
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [["_device", objNull, [objNull]], ["_path", "", [""]]];

if (!hasInterface || {isNull _device} || {_path isEqualTo ""}) exitWith {};

playSound3D [_path, _device, false, getPosASL _device, 3, 1, 20, 0, true];

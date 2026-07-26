// File: fnc_mediaNotify.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Records that a media item (image / video / audio) was opened or closed on a laptop so
 * mission makers can react to it. Media playback is client-local (only the player at the laptop sees
 * or hears it), so these flags and events live on the VIEWING CLIENT only - nothing is broadcast.
 *
 * Side effects (all on the viewing client):
 *  - raises the local CBA event "ae3_desktop_mediaOpened" or "ae3_desktop_mediaClosed" with the
 *    payload [_computer, _type, _sourcePath, _vfsPath]
 *  - on the laptop object:
 *      AE3_desktop_mediaOpen  <ARRAY> - currently-open items, each [type, sourcePath, vfsPath]
 *      AE3_desktop_mediaSeen  <ARRAY> - every source path that has been opened on this client
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 * 1: _type <STRING> - "image" | "video" | "audio"
 * 2: _sourcePath <STRING> - Real media source path
 * 3: _vfsPath <STRING> (Optional, default "") - Virtual filesystem path that was opened
 * 4: _opened <BOOL> (Optional, default true) - true = opened, false = closed
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "image", "media\images\x.jpg", "/home/admin/Desktop/x.jpg", true] call AE3_desktop_fnc_mediaNotify;
 *
 * Public: Yes
 */

params ["_computer", "_type", "_sourcePath", ["_vfsPath", ""], ["_opened", true]];

if (isNull _computer) exitWith {};

private _entry = [_type, _sourcePath, _vfsPath];
private _open = _computer getVariable ["AE3_desktop_mediaOpen", []];

if (_opened) then
{
	_open pushBackUnique _entry;
	private _seen = _computer getVariable ["AE3_desktop_mediaSeen", []];
	_seen pushBackUnique _sourcePath;
	_computer setVariable ["AE3_desktop_mediaSeen", _seen];
}
else
{
	_open = _open - [_entry];
};
_computer setVariable ["AE3_desktop_mediaOpen", _open];

[
	["ae3_desktop_mediaClosed", "ae3_desktop_mediaOpened"] select _opened,
	[_computer, _type, _sourcePath, _vfsPath]
] call CBA_fnc_localEvent;

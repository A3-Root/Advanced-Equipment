#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a media file (image/video/audio shipped in a mod or the mission) so
 * it can be opened on laptops via the Files app or 'cat'. Creates a marker file in the target
 * laptops' filesystems ("AE3_MEDIA|<type>|<source path>"). Server-side; routed from clients.
 * JIP-safe: the registry and filesystems live on the server.
 *
 * Targets:
 * - ARRAY of laptop objects: only those laptops
 * - "all": every initialized AE3 computer
 * - "future": every computer that initializes from now on (plus all current ones)
 *
 * Arguments:
 * 0: _sourcePath <STRING> - Real path of the media file (e.g. "\myMod\video\intel.ogv")
 * 1: _type <STRING> - "image", "video" or "audio"
 * 2: _fsDest <STRING> - Virtual filesystem destination (e.g. "/home/user/intel.ogv")
 * 3: _targets <ARRAY|STRING> (Optional, default: "all") - See above
 *
 * Return Value:
 * None
 *
 * Example:
 * ["\a3\missions_f\video\a_in.ogv", "video", "/home/user/intel.ogv", "all"] call AE3_desktop_fnc_registerMedia;
 *
 * Public: Yes
 */

params ["_sourcePath", "_type", "_fsDest", ["_targets", "all"]];

// Canonicalise the source path: Arma textures/videos use backslash separators. Normalising once here
// keeps the native viewer, the web viewer and any persisted window state in agreement.
_sourcePath = (trim _sourcePath) splitString "/" joinString "\";

if (!isServer) exitWith
{
	["ae3_desktop_registerMedia", [_sourcePath, _type, _fsDest, _targets]] call CBA_fnc_serverEvent;
};

private _marker = format ["AE3_MEDIA|%1|%2", toLower _type, _sourcePath];

// Registered images double as selectable desktop wallpapers (Settings app)
if ((toLower _type) isEqualTo "image") then
{
	private _wallpapers = missionNamespace getVariable ["AE3_Desktop_WallpaperList", []];
	_wallpapers pushBackUnique _sourcePath;
	missionNamespace setVariable ["AE3_Desktop_WallpaperList", _wallpapers, true];
};

private _computers = [];

switch (true) do
{
	case (_targets isEqualType []):
	{
		_computers = _targets;
	};
	case (_targets isEqualTo "all"):
	{
		_computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]);
	};
	case (_targets isEqualTo "future"):
	{
		_computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]);
		ae3_desktop_pendingMedia pushBack [_sourcePath, _type, _fsDest];
	};
	default
	{
		private _targetObject = objectFromNetId _targets;
		if (!isNull _targetObject) then { _computers = [_targetObject]; };
	};
};

{
	if (!isNull _x && {_x getVariable ["AE3_cap_hasFilesystem", false]}) then
	{
		[_x, _fsDest, _marker, false, "root", [[true, true, false], [true, false, false]], false, "caesar", "1"] call AE3_filesystem_fnc_device_addFile;
	};
} forEach _computers;

INFO_3("Registered media %1 -> %2 on %3 computer(s)",_sourcePath,_fsDest,count _computers);

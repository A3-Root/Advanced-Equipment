#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a media file (image/video/audio shipped in a mod or the mission) so
 * it can be opened on laptops via the Files app or 'cat'. Creates a marker file in the target
 * laptops' filesystems ("AE3_MEDIA|<type>|<scope>|<native>|<source path>"). Server-side; routed
 * from clients. JIP-safe: the registry and filesystems live on the server.
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
 * 4: _scope <STRING> (Optional, default: "auto") - Path origin hint: "mod", "mission" or "auto"
 * 5: _native <BOOL> (Optional, default: false) - Allow the native RscPicture fallback for images
 *
 * Return Value:
 * None
 *
 * Example:
 * ["\a3\missions_f\video\a_in.ogv", "video", "/home/user/intel.ogv", "all"] call AE3_desktop_fnc_registerMedia;
 *
 * Public: Yes
 */

params ["_sourcePath", "_type", "_fsDest", ["_targets", "all"], ["_scope", "auto"], ["_native", false]];

// Canonicalise the source path: Arma textures/videos use backslash separators. Normalising once here
// keeps the native viewer, the web viewer and any persisted window state in agreement.
_sourcePath = (trim _sourcePath) splitString "/" joinString "\";

// Normalise the origin hint and the native-fallback flag so the marker is always well formed.
_scope = toLower _scope;
if !(_scope in ["mod", "mission"]) then { _scope = "auto"; };
_native = _native isEqualTo true;

if (!isServer) exitWith
{
	["ae3_desktop_registerMedia", [_sourcePath, _type, _fsDest, _targets, _scope, _native]] call CBA_fnc_serverEvent;
};

private _marker = format ["AE3_MEDIA|%1|%2|%3|%4", toLower _type, _scope, ["0", "1"] select _native, _sourcePath];

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
		ae3_desktop_pendingMedia pushBack [_sourcePath, _type, _fsDest, _scope, _native];
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
if (AE3_DebugMode) then { diag_log format ["[AE3 DEBUG] [%1] registerMedia: type=%2 scope=%3 native=%4 marker=%5", time, toLower _type, _scope, _native, _marker]; };

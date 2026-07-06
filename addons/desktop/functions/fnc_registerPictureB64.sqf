#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers an inline base64 image on the target laptops' filesystems. The raw base64
 * payload is stored as a data-URL picture marker (via device_addFile's picture path) that the in-OS
 * web viewer renders, so an image can be shipped without a real texture file. Server-side; routed
 * from clients. Used by the Zeus Add Media dialog when base64 is pasted instead of a source path.
 *
 * Targets:
 * - ARRAY of laptop objects: only those laptops
 * - "all": every initialized AE3 computer
 * - "future": every computer that initializes from now on (plus all current ones)
 *
 * Arguments:
 * 0: _b64 <STRING> - Raw base64 image data (an optional "data:...;base64," prefix is stripped downstream)
 * 1: _fsDest <STRING> - Virtual filesystem destination (e.g. "/home/user/intel.png")
 * 2: _targets <ARRAY|STRING> (Optional, default: "all") - See above
 * 3: _pictureType <STRING> (Optional, default: "auto") - MIME hint: "auto" or png/jpeg/gif/bmp/webp
 *
 * Return Value:
 * None
 *
 * Example:
 * ["iVBORw0KGgo...", "/home/user/intel.png", "all"] call AE3_desktop_fnc_registerPictureB64;
 *
 * Public: Yes
 */

params ["_b64", "_fsDest", ["_targets", "all"], ["_pictureType", "auto"]];

if (!isServer) exitWith
{
	["ae3_desktop_registerPictureB64", [_b64, _fsDest, _targets, _pictureType]] call CBA_fnc_serverEvent;
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
		ae3_desktop_pendingPictures pushBack [_b64, _fsDest, _pictureType];
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
		// Overwrite any existing (case-insensitive) file at the destination, then store the payload
		// through the picture path (_isPicture true) so it becomes an inline image marker.
		[_x, _fsDest, _b64, false, "root", [[true, true, false], [true, false, false]], false, "caesar", "1", true, true, _pictureType] call AE3_filesystem_fnc_device_addFile;
	};
} forEach _computers;

INFO_2("Registered base64 picture -> %1 on %2 computer(s)",_fsDest,count _computers);

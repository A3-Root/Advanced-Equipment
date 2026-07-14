// File: fnc_mount.sqf
/*
 * Author: Root, Wasserstoff
 * Description: Mounts a flash drive attached to a USB interface, creating a mount point at /mnt/<interface> and making the drive's filesystem accessible to the specified user
 *
 * Arguments:
 * 0: _computer <OBJECT> - Computer object with USB interfaces
 * 1: _interface <STRING> - Name of the USB interface to mount
 * 2: _username <STRING> - ArmaOS username to grant access permissions
 *
 * Return Value:
 * None
 *
 * Example:
 * [laptop, "usb0", "user"] call AE3_flashdrive_fnc_mount;
 *
 * Public: Yes
 */

params['_computer', '_interface', '_username'];

// Wrapped so a failure (e.g. missing interface/empty slot, or the drive object not yet known on a
// dedicated server) is reported to the open "My Computer" view instead of aborting silently and
// leaving the volume stuck on "not mounted".
try
{
	private _filesystem = _computer getVariable "AE3_filesystem";

	private _interfaces = _computer getVariable ["AE3_USB_Interfaces", createHashMap];

	if (!(_interface in _interfaces)) throw (localize "STR_AE3_Flashdrive_Exception_InterfaceNotExisting");

	private _occupiedList = _computer getVariable ["AE3_USB_Interfaces_occupied", []];
	private _mountedList = _computer getVariable ["AE3_USB_Interfaces_mounted", []];
	private _index = (_interfaces get _interface) select 0;
	private _flashdrive = _occupiedList param [_index, objNull];

	if (isNull _flashdrive) throw (localize "STR_AE3_Flashdrive_Exception_InterfaceEmpty");

	if(!isServer) then
	{
		[_flashdrive, "AE3_filesystem"] call AE3_main_fnc_getRemoteVar;
	};
	private _fdFilesystem = _flashdrive getVariable "AE3_filesystem";

	// Lazy init: arsenal-obtained or freshly spawned drives have no filesystem yet - create an
	// empty one on first mount (server holds the authoritative copy)
	if (isNil "_fdFilesystem") then
	{
		_fdFilesystem = [createHashMap, 'root', [[true, true, true], [true, true, true]]];
		_flashdrive setVariable ["AE3_filesystem", _fdFilesystem, 2];
	};

	// Idempotent: mount point may already exist after a re-mount or JIP re-init (fixes
	// "'USB1' already exists!" unhandled exception on dedicated servers)
	[
		[],
		_filesystem,
		format ["/mnt/%1", _interface],
		"root",
		_username
	] call AE3_filesystem_fnc_ensureDir;

	[
		[],
		_filesystem,
		_fdFilesystem,
		format ["/mnt/%1", _interface],
		_username
	] call AE3_filesystem_fnc_mount;

	[
		[],
		_filesystem,
		format ["/mnt/%1", _interface],
		"root",
		_username,
		true
	] call AE3_filesystem_fnc_chown;

	// A drive is built with the same root permissions a laptop's filesystem gets: owned by root, and
	// readable but not writable by anyone else. That is right for a machine's own root directory and
	// wrong for a removable drive, which is there to be written to - only the account the drive was
	// chowned to could put a file on it, and every other account on the same laptop was refused. Every
	// directory on the drive is opened to all of them, which is what makes a copy onto the drive land,
	// since creating an entry is a write against the directory that will hold it. Files are left with
	// whatever permissions they were given, so a drive carrying deliberately locked or encrypted
	// content still carries it locked.
	private _openDirs = {
		params ["_fsObject", "_apply"];
		if (!((_fsObject select 0) isEqualType createHashMap)) exitWith {};
		_fsObject set [2, [[true, true, true], [true, true, true]]];
		{
			[_y, _apply] call _apply;
		} forEach (_fsObject select 0);
	};
	[_fdFilesystem, _openDirs] call _openDirs;

	_computer setVariable ["AE3_filesystem", _filesystem, [_computer] call AE3_armaos_fnc_computer_getLocality];

	_mountedList set [_index, true];
	_computer setVariable ["AE3_USB_Interfaces_mounted", _mountedList, [_computer] call AE3_armaos_fnc_computer_getLocality];

	// Nudge any open "My Computer" view to re-list now that the mount has actually completed; the
	// mount runs asynchronously on the server, so the UI cannot rely on the request reply alone.
	["ae3_desktop_volChanged", []] call CBA_fnc_globalEvent;
}
catch
{
	diag_log text format ["[AE3][USB] mount of '%1' on %2 failed: %3", _interface, _computer, _exception];
	["ae3_desktop_volError", [if (_exception isEqualType "") then { _exception } else { str _exception }]] call CBA_fnc_globalEvent;
};

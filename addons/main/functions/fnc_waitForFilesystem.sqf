// File: fnc_waitForFilesystem.sqf
/*
 * Author: Root
 * Description: DEPRECATED - Waits for a computer's filesystem to be ready before proceeding (blocking, scheduled environment only).
 * Internal callers were migrated to the server event "ae3_main_zeusDeviceOp" / AE3_armaos_fnc_device_ensureInit.
 * Kept for external API compatibility.
 *
 * Arguments:
 * 0: _computer <OBJECT> - Computer object to check
 * 1: _timeoutSeconds <NUMBER> (Optional) - Timeout duration in seconds, default: 10
 *
 * Return Value:
 * Success <BOOL> - true if filesystem is ready, false if timeout occurred
 *
 * Example:
 * private _ready = [_computer] call AE3_main_fnc_waitForFilesystem;
 * private _ready = [_computer, 15] call AE3_main_fnc_waitForFilesystem;
 *
 * Public: Yes
 */

params ["_computer", ["_timeoutSeconds", 10]];

// Check if filesystem is ready
private _startTime = time;
private _timeout = _startTime + _timeoutSeconds;
private _filesystemReady = false;

waitUntil {
	_filesystemReady = _computer getVariable ["AE3_filesystemReady", false];
	_filesystemReady || time > _timeout
};

// Return success status
_filesystemReady

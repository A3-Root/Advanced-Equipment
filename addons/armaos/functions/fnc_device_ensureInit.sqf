#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Ensures a computer's filesystem is initialized (server only). If the device has not
 * been initialized yet but has an AE3_Device config, initialization is run on demand. Returns false
 * for objects that are not AE3 devices (e.g. vanilla laptop props placed in Zeus).
 *
 * Arguments:
 * 0: _computer <OBJECT> - Computer object to ensure initialization for
 *
 * Return Value:
 * true if the filesystem is ready, false if the object is not an AE3 device or init failed <BOOL>
 *
 * Example:
 * private _ready = [_laptop] call AE3_armaos_fnc_device_ensureInit;
 *
 * Public: Yes
 */

params ["_computer"];

if (!isServer) exitWith { false };
if (isNull _computer) exitWith { false };

if (_computer getVariable ["AE3_filesystemReady", false]) exitWith { true };

// Not initialized yet - only possible for actual AE3 devices
private _deviceCfg = configOf _computer >> "AE3_Device";
if (!isClass _deviceCfg) exitWith { false };

INFO_1("Running on-demand init for %1",typeOf _computer);
[_computer, configFile >> 'AE3_FilesystemObjects'] call AE3_armaos_fnc_device_initComplete;

_computer getVariable ["AE3_filesystemReady", false]

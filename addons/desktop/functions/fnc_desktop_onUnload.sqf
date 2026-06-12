#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Unload handler of the desktop display: runs app onClose callbacks, pushes the
 * filesystem back to the server, releases the mutex and restores the laptop screen texture.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The desktop display
 * 1: _exitCode <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * Wired via the AE3_Desktop_Display config (onUnload).
 *
 * Public: No
 */

params ["_display", "_exitCode"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _computer = _session getOrDefault ["computer", objNull];

// Run app close callbacks
{
	private _callbacks = _y getOrDefault ["callbacks", createHashMap];
	private _onClose = _callbacks getOrDefault ["onClose", {}];
	[_x, _computer] call _onClose;
} forEach (_session getOrDefault ["windows", createHashMap]);

uiNamespace setVariable ["AE3_desktop_session", nil];

if (isNull _computer) exitWith {};

// Push filesystem changes back to the server
private _filesystem = _computer getVariable ["AE3_filesystem", nil];
if (!isNil "_filesystem") then
{
	_computer setVariable ["AE3_filesystem", _filesystem, 2];
};
_computer setVariable ["AE3_filepointer", _computer getVariable ["AE3_filepointer", []], 2];

// Restore the running screen texture and release the laptop
_computer setObjectTextureGlobal [1, "\z\ae3\addons\armaos\textures\Laptop_4_to_3_On.paa"];
_computer setVariable ["AE3_computer_mutex", objNull, true];

[_computer, "inUse", false] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];

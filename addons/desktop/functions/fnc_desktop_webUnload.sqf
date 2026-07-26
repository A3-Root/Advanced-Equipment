// File: fnc_desktop_webUnload.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Unload handler for the web desktop browser display. Mirrors the native desktop
 * cleanup: pushes filesystem changes back to the server, restores the laptop's running screen
 * texture, releases the mutex (AE3_computer_mutex) and clears the ACE "in use" state so the laptop
 * is available again. Wired via the AE3_Desktop_BrowserDisplay config onUnload.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The browser display
 * 1: _exitCode <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_display", "_exitCode"];

uiNamespace setVariable [QGVAR(browserCtrl), nil];

private _computer = _display getVariable [QGVAR(computer), objNull];
if (isNull _computer) exitWith {};

// Persist filesystem mutations made through the Files/Notepad apps.
private _filesystem = _computer getVariable ["AE3_filesystem", nil];
if (!isNil "_filesystem") then {
    _computer setVariable ["AE3_filesystem", _filesystem, 2];
};

// Restore the running screen texture (GUI idle image) and release the laptop.
[_computer, "\z\ae3\addons\armaos\textures\Laptop_PowerOn.paa"] call AE3_armaos_fnc_computer_release;

// The session is over, so the watchers that pull a user out of a laptop they can no longer be at (death,
// unconsciousness, respawn) have nothing left to guard.
missionNamespace setVariable ["AE3_computer_session", objNull];

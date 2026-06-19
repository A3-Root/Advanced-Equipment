#include "..\script_component.hpp"
/*
 * Author: Root, Wasserstoff, y0014984
 * Description: Unload handler for the terminal dialog: releases the mutex, removes the
 * per-frame handlers and syncs the serializable terminal state back to the server.
 *
 * Arguments:
 * 0: _display <DISPLAY> - The terminal dialog being closed
 * 1: _exitCode <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * _consoleDialog displayAddEventHandler ["Unload", { _this call AE3_armaos_fnc_terminal_onUnload }];
 *
 * Public: No
 */

params ["_display", "_exitCode"];

private _computer = _display getVariable "AE3_computer";

// End an active SSH session (releases the remote mutex and pushes the remote filesystem)
[_computer] call AE3_armaos_fnc_shell_sshEnd;

_computer setVariable ["AE3_computer_mutex", objNull, true];

private _handleUpdateBatteryStatus = _display getVariable "AE3_handleUpdateBatteryStatus";
[_handleUpdateBatteryStatus] call CBA_fnc_removePerFrameHandler;


/* ------------- UI on Texture ------------ */

private _handleUpdateUiOnTexture = _display getVariable "AE3_handleUpdateUiOnTexture";
[_handleUpdateUiOnTexture] call CBA_fnc_removePerFrameHandler;

/* ---------------------------------------- */

// Sync only essential terminal data to avoid serialization warnings
private _terminal = _computer getVariable "AE3_terminal";

// Extract only essential data for network sync (avoid HashMap serialization)
private _terminalSyncData = [
	_terminal get "AE3_terminalBuffer",
	_terminal get "AE3_terminalApplication",
	_terminal get "AE3_terminalPrompt",
	_terminal get "AE3_terminalScrollPosition",
	_terminal get "AE3_terminalLoginUser",
	_terminal get "AE3_terminalCommandHistory"
];
_computer setVariable ["AE3_terminal_sync", _terminalSyncData, [clientOwner, 2]];

private _filepointer = _computer getVariable "AE3_filepointer";
_computer setVariable ["AE3_filepointer", _filepointer, [clientOwner, 2]];

// CLI home screen: restore the classic terminal idle texture when the STANDALONE terminal closes.
// When the terminal runs inside the (native) desktop, an AE3_desktop_session is active and that
// desktop manages the screen (lock texture while open, idle image on its own unload) - don't touch
// it here, or we'd clobber the desktop lock screen.
private _inDesktop = !isNull ((uiNamespace getVariable ["AE3_desktop_session", createHashMap]) getOrDefault ["display", displayNull]);
if (!_inDesktop) then {
    _computer setObjectTextureGlobal [1, "\z\ae3\addons\armaos\textures\Laptop_4_to_3_On.paa"];
};

[_computer, "inUse", false] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];

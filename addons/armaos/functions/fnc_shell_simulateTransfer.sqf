#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Simulates a file transfer by blocking the calling (scheduled) command process
 * for a duration derived from the file size and the configured medium speed, while printing
 * progress to the terminal. Cancellable with Ctrl+C (terminates the command process).
 * NOTE: must run in a scheduled environment (OS commands run spawned) - uses sleep by design.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object
 * 1: _bytes <NUMBER> - Simulated file size in bytes (e.g. character count of the content)
 * 2: _medium <STRING> (Optional, default: "local") - "local", "usb" or "network"
 *
 * Return Value:
 * Duration of the simulated transfer in seconds <NUMBER>
 *
 * Example:
 * [_computer, 1024 * 512, "usb"] call AE3_armaos_fnc_shell_simulateTransfer;
 *
 * Public: Yes
 */

params ["_computer", "_bytes", ["_medium", "local"]];

// Speeds are configured in KB/s via CBA settings
private _speed = switch (toLower _medium) do
{
	case "usb":     { missionNamespace getVariable ["AE3_TransferSpeedUsb", 2048] };
	case "network": { missionNamespace getVariable ["AE3_TransferSpeedNetwork", 512] };
	default         { missionNamespace getVariable ["AE3_TransferSpeedLocal", 20480] };
};

// 0 = instant transfers (simulation disabled)
if (_speed <= 0) exitWith { 0 };

private _duration = (_bytes / 1024) / _speed;

// Not worth simulating
if (_duration < 0.5) exitWith { 0 };

private _kb = round (_bytes / 1024);
private _start = CBA_missionTime;

[_computer, format [localize "STR_AE3_ArmaOS_Transfer_Started", _kb, _speed]] call AE3_armaos_fnc_shell_stdout;

while { (CBA_missionTime - _start) < _duration } do
{
	private _percent = (((CBA_missionTime - _start) / _duration) * 100) min 100;
	[_computer, format ["  %1%2", floor _percent, "%"]] call AE3_armaos_fnc_shell_stdout;

	sleep (1 max (_duration / 10));
};

[_computer, localize "STR_AE3_ArmaOS_Transfer_Done"] call AE3_armaos_fnc_shell_stdout;

_duration

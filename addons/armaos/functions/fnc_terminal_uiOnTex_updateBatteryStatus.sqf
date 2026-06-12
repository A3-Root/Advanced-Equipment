/*
 * Author: Root, y0014984
 * Description: Updates battery status on UI-on-Texture displays for nearby players.
 *
 * Arguments:
 * 0: _computer <OBJECT> - TODO: Add description
 * 1: _value <STRING> - TODO: Add description
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer, _value] call AE3_armaos_fnc_terminal_uiOnTex_updateBatteryStatus;
 *
 * Public: No
 */

params ["_computer", "_value"];

if (!hasInterface) exitWith {};

private _uiOnTexActive = _computer getVariable ["AE3_UiOnTexActive", false]; // local variable on computer object is sufficient

if (!_uiOnTexActive) then {
	[_computer] call AE3_armaos_fnc_terminal_uiOnTex_init;
};

private _displayName = _computer getVariable ["AE3_UiOnTexDisplayName", "AE3_UiOnTexture"];

if (isNull findDisplay _displayName) exitWith {
	// Re-queue once the render-target display exists (created on first texture draw) - never block
	[
		{ params ["", "_displayName"]; !isNull findDisplay _displayName },
		{ (_this select 0) call AE3_armaos_fnc_terminal_uiOnTex_updateBatteryStatus; },
		[_this, _displayName],
		10
	] call CBA_fnc_waitUntilAndExecute;
};

private _uiOnTextureDisplay = findDisplay _displayName;

private _uiOnTextureBatteryCtrl = _uiOnTextureDisplay displayCtrl 1050; // Battery Control

_uiOnTextureBatteryCtrl ctrlSetText format ["\z\ae3\addons\armaos\images\AE3_battery_%1_percent.paa", _value];

displayUpdate _uiOnTextureDisplay;

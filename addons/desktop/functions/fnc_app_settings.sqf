#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Settings" app: per-laptop theme selection and interface mode switch.
 * The theme is stored on the laptop (public) so it persists for all users of this laptop.
 *
 * Arguments:
 * 0: _winId <NUMBER>
 * 1: _ctrlGroup <CONTROL>
 * 2: _computer <OBJECT>
 * 3: _args <ANY>
 *
 * Return Value:
 * App callbacks <HASHMAP>
 *
 * Public: No
 */

params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

private _label = _display ctrlCreate ["RscText", -1, _ctrlGroup];
_label ctrlSetPosition [0.01, 0.045, _w - 0.02, 0.035];
_label ctrlSetText (localize "STR_AE3_Desktop_Settings_Theme");
_label ctrlSetTextColor (_theme getOrDefault ["accent", [1,1,1,1]]);
_label ctrlCommit 0;

private _listCtrl = _display ctrlCreate ["RscListBox", -1, _ctrlGroup];
_listCtrl ctrlSetPosition [0.01, 0.085, _w - 0.02, _h - 0.18];
_listCtrl ctrlCommit 0;

{
	private _index = _listCtrl lbAdd (getText (_x >> "displayName"));
	_listCtrl lbSetData [_index, configName _x];
} forEach ("isClass _x" configClasses (configFile >> "CfgAE3Themes"));

_listCtrl setVariable ["AE3_computer", _computer];
_listCtrl ctrlAddEventHandler ["LBDblClick", {
	params ["_listCtrl", "_index"];

	private _computer = _listCtrl getVariable "AE3_computer";
	_computer setVariable ["AE3_desktopTheme", _listCtrl lbData _index, true];

	// Re-open the desktop to apply the theme everywhere
	private _display = ctrlParent _listCtrl;
	_display closeDisplay 1;
	[_computer getVariable ["AE3_computer_mutex", player], _computer] call
	{
		params ["_player", "_computer"];
		_computer setVariable ["AE3_computer_mutex", _player, true];
		[_computer] spawn AE3_desktop_fnc_desktop_open;
	};
}];

private _modeBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_modeBtn ctrlSetPosition [0.01, _h - 0.085, _w - 0.02, 0.04];
_modeBtn ctrlSetText (localize "STR_AE3_Desktop_Settings_SwitchCli");
_modeBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_modeBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_modeBtn ctrlCommit 0;

_modeBtn setVariable ["AE3_computer", _computer];
_modeBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _computer = _button getVariable "AE3_computer";

	// Next interaction opens the classic CLI terminal
	[_computer, "cli"] call AE3_desktop_fnc_setInterfaceMode;
	(ctrlParent _button) closeDisplay 1;
}];

createHashMap

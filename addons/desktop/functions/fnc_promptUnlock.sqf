#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Shows a password prompt for a locked file on the desktop. On the correct
 * password the protected payload is opened with the normal file dispatcher (text viewer,
 * media, ...). Wrong attempts are logged to /var/log/auth.log.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 * 1: _path <STRING> - File path (for the prompt title and logging)
 * 2: _password <STRING> - The correct password
 * 3: _payload <STRING> - The protected content
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_computer", "_path", "_password", "_payload"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];
if (isNull _display) exitWith {};

private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_group ctrlSetPosition [safeZoneX + 0.32, safeZoneY + 0.25, 0.36, 0.18];
_group ctrlCommit 0;

private _body = _display ctrlCreate ["RscText", -1, _group];
_body ctrlSetPosition [0, 0, 0.36, 0.18];
_body ctrlSetBackgroundColor (_theme getOrDefault ["window", [0,0,0,1]]);
_body ctrlCommit 0;

private _title = _display ctrlCreate ["RscText", -1, _group];
_title ctrlSetPosition [0, 0, 0.31, 0.04];
_title ctrlSetText format [localize "STR_AE3_Desktop_Unlock_Title", _path];
_title ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_title ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_title ctrlCommit 0;

private _closeBtn = _display ctrlCreate ["RscButton", -1, _group];
_closeBtn ctrlSetPosition [0.31, 0, 0.05, 0.04];
_closeBtn ctrlSetText "X";
_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
_closeBtn ctrlCommit 0;
_closeBtn setVariable ["AE3_group", _group];
_closeBtn ctrlAddEventHandler ["ButtonClick", { ctrlDelete ((_this select 0) getVariable "AE3_group"); }];

private _pwCtrl = _display ctrlCreate ["RscEdit", -1, _group];
_pwCtrl ctrlSetPosition [0.01, 0.06, 0.34, 0.035];
_pwCtrl ctrlCommit 0;

private _okBtn = _display ctrlCreate ["RscButton", -1, _group];
_okBtn ctrlSetPosition [0.01, 0.11, 0.34, 0.04];
_okBtn ctrlSetText (localize "STR_AE3_Desktop_Unlock_Open");
_okBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
_okBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_okBtn ctrlCommit 0;

_okBtn setVariable ["AE3_ctx", [_computer, _path, _password, _payload, _pwCtrl, _group]];
_okBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	((_button getVariable "AE3_ctx")) params ["_computer", "_path", "_password", "_payload", "_pwCtrl", "_group"];

	if ((ctrlText _pwCtrl) isNotEqualTo _password) exitWith
	{
		hintSilent (localize "STR_AE3_ArmaOS_Unlock_WrongPassword");
		[_computer, "System", format ["unlock: wrong password for '%1' (desktop)", _path], "/var/log/auth.log"] call AE3_armaos_fnc_shell_writeToLogfile;
		[_computer] call AE3_armaos_fnc_shell_playErrorSound;
	};

	ctrlDelete _group;
	[_computer, _path, _payload] call AE3_desktop_fnc_openFile;
}];

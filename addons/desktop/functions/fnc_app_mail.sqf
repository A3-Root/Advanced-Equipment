#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Mail" app: reads emails from the /var/mail directory of the laptop
 * filesystem and can send emails to other computers over the AE3 network.
 * Email file format (plantable via Zeus/3DEN AddFile or AE3_desktop_fnc_addEmail):
 *   From: sender name
 *   Subject: subject line
 *   <empty line>
 *   body text...
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

/* mail list (left) */
private _listCtrl = _display ctrlCreate ["RscListBox", -1, _ctrlGroup];
_listCtrl ctrlSetPosition [0.01, 0.045, (_w * 0.35), _h - 0.10];
_listCtrl ctrlCommit 0;

/* reading pane (right) */
private _readCtrl = _display ctrlCreate ["RscStructuredText", -1, _ctrlGroup];
_readCtrl ctrlSetPosition [0.02 + (_w * 0.35), 0.045, _w - 0.03 - (_w * 0.35), _h - 0.10];
_readCtrl ctrlCommit 0;

/* bottom bar: refresh + compose */
private _refreshBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_refreshBtn ctrlSetPosition [0.01, _h - 0.05, 0.12, 0.04];
_refreshBtn ctrlSetText (localize "STR_AE3_Desktop_Mail_Refresh");
_refreshBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_refreshBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_refreshBtn ctrlCommit 0;

private _composeBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_composeBtn ctrlSetPosition [0.14, _h - 0.05, 0.12, 0.04];
_composeBtn ctrlSetText (localize "STR_AE3_Desktop_Mail_Compose");
_composeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
_composeBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_composeBtn ctrlCommit 0;

/* ---------------------------------------- */

_listCtrl setVariable ["AE3_computer", _computer];
_listCtrl setVariable ["AE3_readCtrl", _readCtrl];

private _refresh = {
	params ["_listCtrl"];

	private _computer = _listCtrl getVariable "AE3_computer";
	lbClear _listCtrl;

	private _filesystem = _computer getVariable ["AE3_filesystem", []];
	if (_filesystem isEqualTo []) exitWith {};

	private _mailDir = (_filesystem select 0) getOrDefault ["var", []];
	if (_mailDir isEqualTo []) exitWith {};
	_mailDir = (_mailDir select 0) getOrDefault ["mail", []];
	if (_mailDir isEqualTo []) exitWith {};

	private _names = keys (_mailDir select 0);
	_names sort true;

	{
		private _entry = (_mailDir select 0) get _x;
		private _content = _entry select 0;
		if (_content isEqualType "") then
		{
			// display the Subject line if present, otherwise the file name
			private _subject = _x;
			{
				if ((_x select [0, 8]) isEqualTo "Subject:") exitWith
				{
					_subject = [_x select [8]] call CBA_fnc_trim;
				};
			} forEach (_content splitString endl);

			private _index = _listCtrl lbAdd _subject;
			_listCtrl lbSetData [_index, _x];
		};
	} forEach _names;
};

_listCtrl setVariable ["AE3_refresh", _refresh];
[_listCtrl] call _refresh;

_listCtrl ctrlAddEventHandler ["LBSelChanged", {
	params ["_listCtrl", "_index"];

	private _computer = _listCtrl getVariable "AE3_computer";
	private _readCtrl = _listCtrl getVariable "AE3_readCtrl";
	private _name = _listCtrl lbData _index;

	private _filesystem = _computer getVariable ["AE3_filesystem", []];

	try
	{
		private _content = [[], _filesystem, format ["/var/mail/%1", _name], "root", 0] call AE3_filesystem_fnc_getFile;
		if (_content isEqualType "") then
		{
			_readCtrl ctrlSetStructuredText (parseText ((_content splitString endl) joinString "<br/>"));
		};
	}
	catch
	{
		_readCtrl ctrlSetStructuredText (parseText str _exception);
	};
}];

_refreshBtn setVariable ["AE3_listCtrl", _listCtrl];
_refreshBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _listCtrl = _button getVariable "AE3_listCtrl";
	[_listCtrl] call (_listCtrl getVariable "AE3_refresh");
}];

/* ---------------------------------------- */
/* Compose: simple To/Subject/Body window */

_composeBtn setVariable ["AE3_computer", _computer];
_composeBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];

	private _computer = _button getVariable "AE3_computer";
	private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
	private _display = _session getOrDefault ["display", displayNull];
	private _theme = _session getOrDefault ["theme", createHashMap];

	private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
	_group ctrlSetPosition [safeZoneX + 0.3, safeZoneY + 0.15, 0.42, 0.5];
	_group ctrlCommit 0;

	private _body = _display ctrlCreate ["RscText", -1, _group];
	_body ctrlSetPosition [0, 0, 0.42, 0.5];
	_body ctrlSetBackgroundColor (_theme getOrDefault ["window", [0,0,0,1]]);
	_body ctrlCommit 0;

	private _title = _display ctrlCreate ["RscText", -1, _group];
	_title ctrlSetPosition [0, 0, 0.37, 0.04];
	_title ctrlSetText (localize "STR_AE3_Desktop_Mail_Compose");
	_title ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
	_title ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
	_title ctrlCommit 0;

	private _toCtrl = _display ctrlCreate ["RscEdit", -1, _group];
	_toCtrl ctrlSetPosition [0.01, 0.05, 0.40, 0.035];
	_toCtrl ctrlSetText "192.168.0.";
	_toCtrl ctrlCommit 0;

	private _subjectCtrl = _display ctrlCreate ["RscEdit", -1, _group];
	_subjectCtrl ctrlSetPosition [0.01, 0.09, 0.40, 0.035];
	_subjectCtrl ctrlSetText (localize "STR_AE3_Desktop_Mail_SubjectHint");
	_subjectCtrl ctrlCommit 0;

	private _bodyCtrl = _display ctrlCreate ["RscEditMulti", -1, _group];
	if (isNull _bodyCtrl) then { _bodyCtrl = _display ctrlCreate ["RscEdit", -1, _group]; };
	_bodyCtrl ctrlSetPosition [0.01, 0.13, 0.40, 0.31];
	_bodyCtrl ctrlCommit 0;

	private _sendBtn = _display ctrlCreate ["RscButton", -1, _group];
	_sendBtn ctrlSetPosition [0.01, 0.45, 0.40, 0.04];
	_sendBtn ctrlSetText (localize "STR_AE3_Desktop_Mail_Send");
	_sendBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
	_sendBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
	_sendBtn ctrlCommit 0;

	private _closeBtn = _display ctrlCreate ["RscButton", -1, _group];
	_closeBtn ctrlSetPosition [0.37, 0, 0.05, 0.04];
	_closeBtn ctrlSetText "X";
	_closeBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2,0.5,0.8,1]]);
	_closeBtn ctrlCommit 0;
	_closeBtn setVariable ["AE3_group", _group];
	_closeBtn ctrlAddEventHandler ["ButtonClick", { ctrlDelete ((_this select 0) getVariable "AE3_group"); }];

	_sendBtn setVariable ["AE3_ctx", [_computer, _toCtrl, _subjectCtrl, _bodyCtrl, _group]];
	_sendBtn ctrlAddEventHandler ["ButtonClick", {
		params ["_button"];
		((_button getVariable "AE3_ctx")) params ["_computer", "_toCtrl", "_subjectCtrl", "_bodyCtrl", "_group"];

		private _targetIp = (ctrlText _toCtrl splitString ".") apply { parseNumber _x };
		if (count _targetIp != 4) exitWith { hintSilent (localize "STR_AE3_ArmaOS_Ssh_InvalidAddress"); };

		// route over the simulated network
		([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"];
		if (isNull _target || {_target isEqualTo _computer}) exitWith
		{
			hintSilent format [localize "STR_AE3_ArmaOS_Ssh_NoRoute", ctrlText _toCtrl];
		};

		private _senderIp = [_computer getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str;

		["ae3_desktop_addEmail", [netId _target, _senderIp, ctrlText _subjectCtrl, ctrlText _bodyCtrl]] call CBA_fnc_serverEvent;

		hintSilent format [localize "STR_AE3_ArmaOS_Msg_Sent", ctrlText _toCtrl];
		ctrlDelete _group;
	}];
}];

createHashMap

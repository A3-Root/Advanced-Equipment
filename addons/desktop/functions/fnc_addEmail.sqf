#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Adds an email to a laptop's /var/mail directory (server-side; routed from
 * clients). Mission makers use this to plant intel emails; the Mail desktop app and
 * 'cat /var/mail/<file>' display them. An active terminal/desktop user gets a notification.
 *
 * Arguments:
 * 0: _target <OBJECT|STRING> - Target laptop, its netId, or "all" (all initialized computers)
 * 1: _from <STRING> - Sender shown in the email
 * 2: _subject <STRING> - Subject line
 * 3: _body <STRING> - Email body (use endl for line breaks)
 * 4: _to <STRING> (Optional, default: "") - Recipient shown in the email
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, "informant", "Convoy schedule", "They move at 0400." ] call AE3_desktop_fnc_addEmail;
 * ["all", "HQ", "Briefing", "Check the safehouse."] call AE3_desktop_fnc_addEmail;
 *
 * Public: Yes
 */

params ["_target", "_from", "_subject", "_body", ["_to", ""]];

if (!isServer) exitWith
{
	private _targetId = if (_target isEqualType objNull) then { netId _target } else { _target };
	["ae3_desktop_addEmail", [_targetId, _from, _subject, _body, _to]] call CBA_fnc_serverEvent;
};

private _computers = [];
switch (true) do
{
	case (_target isEqualType objNull): { _computers = [_target]; };
	case (_target isEqualTo "all"):     { _computers = +(missionNamespace getVariable ["ae3_desktop_computers", []]); };
	default                             { _computers = [objectFromNetId _target]; };
};

private _toLine = ["", format ["To: %1%2", _to, endl]] select (_to isNotEqualTo "");
private _content = format ["From: %1%2%3Subject: %4%2%2%5", _from, endl, _toLine, _subject, _body];
private _fileName = format ["mail_%1", round (CBA_missionTime * 10)];

{
	if (!isNull _x && {_x getVariable ["AE3_cap_hasFilesystem", false]}) then
	{
		private _filesystem = _x getVariable ["AE3_filesystem", nil];
		if (!isNil "_filesystem") then
		{
			try
			{
				[[], _filesystem, "/var/mail", "root", "root", [[true, true, true], [true, false, true]]] call AE3_filesystem_fnc_ensureDir;
				[[], _filesystem, format ["/var/mail/%1", _fileName], _content, "root", "root", [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
			}
			catch
			{
				WARNING_1("Could not deliver email: %1",_exception);
			};

			// Notify whoever is using the laptop right now
			private _mutexHolder = _x getVariable ["AE3_computer_mutex", objNull];
			if (!isNull _mutexHolder && {_mutexHolder isKindOf "CAManBase"}) then
			{
				["ae3_network_imNotify", [_x, _from], _mutexHolder] call CBA_fnc_targetEvent;
			};
		};
	};
} forEach _computers;

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Routes an email by registered address and delivers it to the recipient laptop.
 *
 * Arguments:
 * 0: _owner <NUMBER> - Client owner to receive the browser reply
 * 1: _rid <STRING> - Browser request id
 * 2: _senderNetId <STRING> - Sending laptop netId
 * 3: _from <STRING> - Registered sender address
 * 4: _to <STRING> - Recipient address
 * 5: _subject <STRING> - Subject line
 * 6: _body <STRING> - Email body
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_owner", -1, [0]], ["_rid", "", [""]], ["_senderNetId", "", [""]], ["_from", "", [""]], ["_to", "", [""]], ["_subject", "", [""]], ["_body", "", [""]]];

if (!isServer) exitWith {};

private _res = createHashMapFromArray [["error", ""]];
private _reply = {
	params ["_owner", "_rid", "_payload"];
	["ae3_desktop_routeReply", [_rid, "mail_send", _payload], _owner] call CBA_fnc_ownerEvent;
};
private _sender = objectFromNetId _senderNetId;
private _registry = missionNamespace getVariable ["AE3_mail_addresses", createHashMap];
private _fromEntry = _registry getOrDefault [toLower ([_from] call CBA_fnc_trim), []];
private _toEntry = _registry getOrDefault [toLower ([_to] call CBA_fnc_trim), []];
if (isNull _sender || {_fromEntry isEqualTo [] || {_toEntry isEqualTo []}}) exitWith {
	_res set ["error", "bad_addr"];
	[_owner, _rid, _res] call _reply;
};
if ((_fromEntry param [0, ""]) isNotEqualTo _senderNetId) exitWith {
	_res set ["error", "bad_sender"];
	[_owner, _rid, _res] call _reply;
};

private _target = objectFromNetId (_toEntry param [0, ""]);
private _connected = {
	params ["_device"];
	private _parent = _device getVariable ["AE3_network_parent", objNull];
	!isNull _parent && {(_device getVariable ["AE3_power_powerState", 0]) == 1} && {(_parent getVariable ["AE3_power_powerState", 0]) == 1}
};
if (isNull _target || {!([_sender] call _connected) || {!([_target] call _connected)}}) exitWith {
	_res set ["error", "unreachable"];
	[_owner, _rid, _res] call _reply;
};

[_target, _fromEntry param [1, _from], _subject, _body] call AE3_desktop_fnc_addEmail;
_res set ["ok", true];
[_owner, _rid, _res] call _reply;

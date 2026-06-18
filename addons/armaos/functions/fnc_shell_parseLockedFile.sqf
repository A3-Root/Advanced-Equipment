#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Parses a possibly password-protected file content. Locked files use the
 * format "AE3_LOCKED|<passwordLength>|<password><payload>" - the length prefix lets the
 * password contain any character (incl. '|'), and the payload may be any text including media
 * markers, pipes and line breaks. A legacy "AE3_LOCKED|<password>|<payload>" form (password
 * without '|') is still accepted for hand-authored content.
 *
 * Arguments:
 * 0: _content <STRING> - File content
 *
 * Return Value:
 * [isLocked <BOOL>, password <STRING>, payload <STRING>] - for unlocked files the payload
 * is the original content and password is "" <ARRAY>
 *
 * Example:
 * ([_content] call AE3_armaos_fnc_shell_parseLockedFile) params ["_locked", "_password", "_payload"];
 *
 * Public: Yes
 */

params ["_content"];

if (!(_content isEqualType "")) exitWith { [false, "", _content] };
if ((_content select [0, 11]) isNotEqualTo "AE3_LOCKED|") exitWith { [false, "", _content] };

private _rest = _content select [11];
private _sep = _rest find "|";

if (_sep < 0) exitWith { [false, "", _content] };

private _head = _rest select [0, _sep];
private _after = _rest select [_sep + 1];

// Current format: head is the password length, so the password may contain '|'.
if (_head isNotEqualTo "" && {_head regexMatch "^\d+$"}) exitWith
{
	private _plen = parseNumber _head;
	[true, _after select [0, _plen], _after select [_plen]]
};

// Legacy format: head is the password itself (no '|' allowed in it).
[true, _head, _after]

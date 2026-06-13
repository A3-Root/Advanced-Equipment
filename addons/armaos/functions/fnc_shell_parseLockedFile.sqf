#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Parses a possibly password-protected file content. Locked files use the
 * format "AE3_LOCKED|<password>|<payload>" - the payload may be any text including media
 * markers, and may itself contain pipes and line breaks.
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

[true, _rest select [0, _sep], _rest select [_sep + 1]]

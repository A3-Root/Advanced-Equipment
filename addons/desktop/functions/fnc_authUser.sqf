#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Validates a username/password against a computer's synced AE3_Userlist for the web
 * desktop login (issue #9). Mirrors the CLI rules: root is blocked unless AE3_AllowRootLogin is
 * set. The userlist is broadcast by AE3_armaos_fnc_computer_addUser, so validation is local (no
 * server round-trip), matching the terminal login. Returns a result hashmap for AE3_recv.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop this session is bound to
 * 1: _user <STRING> - Entered username
 * 2: _pass <STRING> - Entered password
 *
 * Return Value:
 * Result <HASHMAP> - keys: "ok" <BOOL>, "message" <STRING>, "user" <STRING>, "hostname" <STRING>
 *
 * Example:
 * [_laptop, "admin", "admin123"] call AE3_desktop_fnc_authUser;
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]], ["_user", "", [""]], ["_pass", "", [""]]];

private _fail = {
    params ["_msg"];
    createHashMapFromArray [["ok", false], ["message", _msg]]
};

if (isNull _computer) exitWith { ["No device" ] call _fail };
if (_user isEqualTo "") exitWith { ["Enter a username"] call _fail };

private _rootBlocked = (_user isEqualTo "root") && {!(missionNamespace getVariable ["AE3_AllowRootLogin", false])};
if (_rootBlocked) exitWith { ["Root login is disabled"] call _fail };

private _users = _computer getVariable ["AE3_Userlist", createHashMap];
if (!(_user in _users)) exitWith { ["Unknown user"] call _fail };
if ((_users get _user) isNotEqualTo _pass) exitWith { ["Incorrect password"] call _fail };

private _host = _computer getVariable ["ace_cargo_customName", "ae3-os"];
createHashMapFromArray [["ok", true], ["user", _user], ["hostname", _host]]

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: JS->SQF bridge / command dispatcher for the web desktop (WS-B). Bound as the
 * "JSDialog" event handler of the type-106 browser control. The HTML/JS side calls A3.send /
 * A3.request, which raise JSDialog with a JSON string {command, rid, data}. This is the single
 * choke point for all web-app commands: it decodes the request, dispatches to the relevant AE3
 * backend, and (for A3.request) replies via AE3_desktop_fnc_jsSend, echoing the rid so the JS
 * Promise resolves. Keeps the network surface to one EH per client.
 *
 * Arguments:
 * 0: _control <CONTROL> - The browser control that raised the event
 * 1: _isConfirm <BOOL> - true if the JS side used confirm(), false for alert()
 * 2: _message <STRING> - The raw JSON payload string sent from JS
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Public: No
 */

params [["_control", controlNull, [controlNull]], ["_isConfirm", false, [false]], ["_message", "", [""]]];

if (_message isEqualTo "") exitWith { true };

// _objectType 2 = native hash map. The default (0) returns a CBA namespace (LOCATION), which fails
// the isEqualType check below and the getOrDefault/hashmap reads throughout this dispatcher.
private _req = [_message, 2] call CBA_fnc_parseJSON;
if (isNil "_req" || {!(_req isEqualType createHashMap)}) exitWith {
    diag_log text format ["[AE3 desktop] unparseable JS payload: %1", _message];
    true
};

private _command = _req getOrDefault ["command", ""];
private _rid = _req getOrDefault ["rid", ""];
private _data = _req getOrDefault ["data", createHashMap];
if !(_data isEqualType createHashMap) then { _data = createHashMap; };

private _display = ctrlParent _control;
private _computer = _display getVariable [QGVAR(computer), objNull];

if ((missionNamespace getVariable [QGVAR(debug), false]) || {missionNamespace getVariable ["AE3_DebugMode", false]}) then {
    systemChat format ["[AE3] JS: %1", _command];
    diag_log text format ["[AE3 desktop] JS->SQF '%1' rid=%2 data=%3", _command, _rid, _data];
};

// Reply helper: only sends when the JS side used A3.request (has a rid).
private _reply = {
    params ["_payload"];
    if (_rid isEqualTo "") exitWith {};
    [_command, createHashMapFromArray [["_rid", _rid], ["data", _payload]]] call FUNC(jsSend);
};

switch (_command) do {

    // UI is up: seed the hostname only (does NOT skip login - the user still authenticates via
    // "login"). Auto-login, when wanted, is a separate explicit "boot" push.
    case "ready": {
        if (!isNull _computer) then {
            private _host = _computer getVariable ["ace_cargo_customName", "ae3-os"];
            ["hostname", createHashMapFromArray [["hostname", _host]]] call FUNC(jsSend);
        };
        // Push apps registered by other addons (e.g. Root Cyberwarfare) into the launcher.
        private _ext = missionNamespace getVariable [QGVAR(extApps), []];
        if (_ext isNotEqualTo []) then { ["ext_apps", _ext] call FUNC(jsSend); };
    };

    // Login against the synced user list (issue #9). Replies synchronously (the proven path).
    // authUser kicks a non-blocking userlist re-pull and returns "retry" when the account has not
    // reached this client yet (MP race right after a Zeus "Add User"); the JS side retries once.
    // The userlist is normally already cached by the open-time background sync (desktop_openWeb), so
    // the common case takes a single round-trip.
    case "login": {
        private _user = _data getOrDefault ["user", ""];
        private _pass = _data getOrDefault ["pass", ""];
        private _res = [_computer, _user, _pass] call FUNC(authUser);
        if (_res getOrDefault ["ok", false]) then {
            _display setVariable [QGVAR(user), _user];
        };
        [_res] call _reply;
    };

    // --- Filesystem (Files + Notepad), permission-scoped per logged-in user (#9). ---
    case "fs_list";
    case "fs_read";
    case "fs_save";
    case "fs_mkdir";
    case "fs_delete": {
        private _user = _display getVariable [QGVAR(user), ""];
        private _op = _command select [3]; // strip "fs_"
        [[_computer, _user, _op, _data] call FUNC(fsHandle)] call _reply;
    };

    // --- Network (#11) + system info (#14). ---
    case "net_scan": { [[_computer] call FUNC(netScan)] call _reply; };
    case "sysinfo":  { [[_computer] call FUNC(sysInfo)] call _reply; };
    // Calendar intel events. The store (AE3_calendar_events) is broadcast by the server, so the
    // client reads it locally and the JS app caches the whole set on open (#12). Returns every
    // event as {date,title,location,body,index}; the app filters per month client-side.
    case "cal_list": {
        private _events = _computer getVariable ["AE3_calendar_events", []];
        private _out = [];
        {
            _x params [["_date", ""], ["_title", ""], ["_loc", ""], ["_body", ""]];
            _out pushBack createHashMapFromArray [
                ["date", _date], ["title", _title], ["location", _loc], ["body", _body], ["index", _forEachIndex]
            ];
        } forEach _events;
        [_out] call _reply;
    };
    case "cal_add": {
        private _ares = createHashMapFromArray [["error", ""]];
        private _date = _data getOrDefault ["date", ""];
        private _title = _data getOrDefault ["title", ""];
        if (isNull _computer || {_date isEqualTo "" || {_title isEqualTo ""}}) then { _ares set ["error", "bad_input"]; }
        else {
            [_computer, _date, _title, _data getOrDefault ["location", ""], _data getOrDefault ["body", ""]] remoteExec ["AE3_armaos_fnc_computer_addCalendarEvent", 2];
            _ares set ["ok", true];
        };
        [_ares] call _reply;
    };
    case "cal_delete": {
        private _dres = createHashMapFromArray [["error", ""]];
        private _idx = _data getOrDefault ["index", -1];
        if (isNull _computer || {_idx < 0}) then { _dres set ["error", "bad_input"]; }
        else {
            [_computer, _idx] remoteExec ["AE3_armaos_fnc_computer_removeCalendarEvent", 2];
            _dres set ["ok", true];
        };
        [_dres] call _reply;
    };

    // In-window minimap data (#13/#20).
    case "map_data": { [[_computer, _data] call FUNC(mapData)] call _reply; };

    // Mail (#18).
    case "mail_list": { [[_computer, "list", _data] call FUNC(mailHandle)] call _reply; };
    case "mail_read": { [[_computer, "read", _data] call FUNC(mailHandle)] call _reply; };
    case "mail_send": {
        private _mres = createHashMapFromArray [["error", ""]];
        private _targetIp = ((_data getOrDefault ["to", ""]) splitString ".") apply { parseNumber _x };
        if (isNull _computer || {count _targetIp != 4}) then { _mres set ["error", "bad_addr"]; }
        else {
            ([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"];
            if (isNull _target || {_target isEqualTo _computer}) then { _mres set ["error", "no_route"]; }
            else {
                private _senderIp = [_computer getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str;
                ["ae3_desktop_addEmail", [netId _target, _senderIp, _data getOrDefault ["subject", ""], _data getOrDefault ["body", ""]]] call CBA_fnc_serverEvent;
                _mres set ["ok", true];
            };
        };
        [_mres] call _reply;
    };

    // Messenger (#18): pull live inbox (server round-trip -> pushed back as "chat_data") + send IM.
    case "chat_pull": {
        if (!isNull _computer) then {
            ["ae3_desktop_chatPull", [clientOwner, netId _computer]] call CBA_fnc_serverEvent;
        };
    };
    case "chat_send": {
        private _cres = createHashMapFromArray [["error", ""]];
        private _targetIp = ((_data getOrDefault ["to", ""]) splitString ".") apply { parseNumber _x };
        if (isNull _computer || {count _targetIp != 4}) then { _cres set ["error", "bad_addr"]; }
        else {
            ([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"];
            if (isNull _target || {_target isEqualTo _computer}) then { _cres set ["error", "no_route"]; }
            else {
                private _senderIp = [_computer getVariable ["AE3_network_address", [127, 0, 0, 1]]] call AE3_network_fnc_ip2str;
                ["ae3_network_imSend", [netId _target, _senderIp, _data getOrDefault ["text", ""]]] call CBA_fnc_serverEvent;
                _cres set ["ok", true];
            };
        };
        [_cres] call _reply;
    };

    case "net_connect": {
        private _netId = _data getOrDefault ["netId", ""];
        if (_netId isNotEqualTo "" && {!isNull _computer}) then {
            private _router = objectFromNetId _netId;
            if (!isNull _router) then {
                [_computer, _router] remoteExec ["AE3_desktop_fnc_netConnectServer", 2];
            };
        };
    };

    case "net_disconnect": {
        if (!isNull _computer) then {
            [_computer] remoteExec ["AE3_desktop_fnc_netDisconnectServer", 2];
        };
    };

    // Sign out (#8): drop the session user; the JS side re-shows the login overlay. The display
    // (and the laptop claim/mutex) stay - this is a user switch, not a shutdown.
    case "signout": {
        _display setVariable [QGVAR(user), ""];
    };

    // Shut down (#8): close the desktop (the AE3_Desktop_BrowserDisplay onUnload restores the idle
    // texture, releases the mutex and clears the ACE "in use" state) then power the laptop off.
    case "shutdown": {
        if (!isNull _computer) then {
            [_computer] remoteExec ["AE3_armaos_fnc_computer_turnOff", 2];
        };
        _display closeDisplay 0;
    };

    default {
        // Extension commands registered by other addons via AE3_desktop_fnc_registerCmd.
        private _handlers = missionNamespace getVariable [QGVAR(cmdHandlers), createHashMap];
        if (_command in _handlers) then {
            private _user = _display getVariable [QGVAR(user), ""];
            [_computer, _user, _data, _rid, _command] call (_handlers get _command);
        } else {
            diag_log text format ["[AE3 desktop] unhandled JS command '%1': %2", _command, _message];
        };
    };
};

true

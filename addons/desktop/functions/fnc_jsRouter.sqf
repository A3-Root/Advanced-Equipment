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
            private _host = _computer getVariable ["ace_cargo_customName", "armaOS"];
            ["hostname", createHashMapFromArray [["hostname", _host]]] call FUNC(jsSend);
        };
        // Push apps registered by other addons (e.g. Root Cyberwarfare) into the launcher.
        private _ext = missionNamespace getVariable [QGVAR(extApps), []];
        if (_ext isNotEqualTo []) then { ["ext_apps", _ext] call FUNC(jsSend); };
        // Seamless re-entry: if the laptop still has an active session (the previous user did
        // NOT sign out), auto-resume that session instead of demanding the password again. Anyone who
        // opens the laptop continues where it was left.
        if (!isNull _computer) then {
            private _session = _computer getVariable [QGVAR(sessionUser), ""];
            if (_session isNotEqualTo "") then {
                _display setVariable [QGVAR(user), _session];
                private _host = _computer getVariable ["ace_cargo_customName", "armaOS"];
                ["boot", createHashMapFromArray [["user", _session], ["hostname", _host]]] call FUNC(jsSend);
            };
        };
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
            // Persist the session on the laptop so closing/reopening resumes without re-login.
            if (!isNull _computer) then { _computer setVariable [QGVAR(sessionUser), _user, true]; };
        };
        [_res] call _reply;
    };

    // --- Filesystem (Files + Notepad), permission-scoped per logged-in user. ---
    case "fs_list";
    case "fs_read";
    case "fs_unlock";
    case "fs_save";
    case "fs_mkdir";
    case "fs_delete";
    case "fs_move";
    case "fs_copy";
    case "fs_symlink";
    case "fs_search";
    case "fs_restore";
    case "fs_purge";
    case "fs_empty_trash": {
        private _user = _display getVariable [QGVAR(user), ""];
        private _op = _command select [3]; // strip "fs_"
        [[_computer, _user, _op, _data] call FUNC(fsHandle)] call _reply;
    };

    // --- Network + system info. ---
    // My Computer volumes: list/mount/unmount USB drives.
    case "vol_list";
    case "vol_mount";
    case "vol_unmount": {
        private _user = _display getVariable [QGVAR(user), ""];
        private _op = _command select [4]; // strip "vol_"
        [[_computer, _user, _op, _data] call FUNC(volHandle)] call _reply;
    };

    case "net_scan": { [[_computer] call FUNC(netScan)] call _reply; };
    case "sysinfo":  { [[_computer, _display getVariable [QGVAR(user), ""]] call FUNC(sysInfo)] call _reply; };
    // Calendar intel events. The store (AE3_calendar_events) is broadcast by the server, so the
    // client reads it locally and the JS app caches the whole set on open. Returns every
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

    // Cryptography apps: caesar/columnar crypto + cryptanalysis, GUI-side of the CLI tools.
    case "crypto_run": { [[_data] call FUNC(cryptoRun)] call _reply; };
    case "crack_run":  { [[_data] call FUNC(crackRun)] call _reply; };

    // Native real-world map overlay: CEF cannot host the map control, so open it as a dialog.
    case "map_open": { [_computer, _data] call FUNC(mapOpen); };

    // Settings: change system name / wallpaper, applied server-side and broadcast.
    case "sys_set": {
        private _sres = createHashMapFromArray [["error", ""]];
        if (isNull _computer) then { _sres set ["error", "no_device"]; }
        else {
            [_computer, _data getOrDefault ["hostname", ""], _data getOrDefault ["wallpaper", ""]] remoteExec ["AE3_desktop_fnc_setSystemConfig", 2];
            _sres set ["ok", true];
        };
        [_sres] call _reply;
    };

    // Mail.
    case "mail_list": { [[_computer, "list", _data] call FUNC(mailHandle)] call _reply; };
    case "mail_read": { [[_computer, "read", _data] call FUNC(mailHandle)] call _reply; };
    case "mail_delete": { [[_computer, "delete", _data] call FUNC(mailHandle)] call _reply; };
    case "mail_send": {
        private _mres = createHashMapFromArray [["error", ""]];
        private _targetIp = ((_data getOrDefault ["to", ""]) splitString ".") apply { parseNumber _x };
        private _ownIp = _computer getVariable ["AE3_network_address", [127, 0, 0, 1]];
        if (isNull _computer || {count _targetIp != 4}) then { _mres set ["error", "bad_addr"]; }
        else {
            // Loopback: sending to your own address (or 127.0.0.1) delivers to this same laptop -
            // ping returns null for self, so resolve it directly instead of failing with no_route.
            private _isLoopback = (_targetIp isEqualTo _ownIp) || {_targetIp isEqualTo [127, 0, 0, 1]};
            private _target = _computer;
            if (!_isLoopback) then { ([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"]; };
            // Reject ghost IPs: route must resolve and the device must own the requested address.
            private _valid = !isNull _target
                && {_isLoopback || {(_target getVariable ["AE3_network_address", []]) isEqualTo _targetIp}}
                && {_isLoopback || {_ownIp isNotEqualTo [127, 0, 0, 1]}};
            if (_valid) then {
                private _senderIp = [_ownIp] call AE3_network_fnc_ip2str;
                ["ae3_desktop_addEmail", [netId _target, _senderIp, _data getOrDefault ["subject", ""], _data getOrDefault ["body", ""]]] call CBA_fnc_serverEvent;
                _mres set ["ok", true];
            } else { _mres set ["error", "no_route"]; };
        };
        [_mres] call _reply;
    };

    // Messenger: pull live inbox (server round-trip -> pushed back as "chat_data") + send IM.
    case "chat_pull": {
        if (!isNull _computer) then {
            ["ae3_desktop_chatPull", [clientOwner, netId _computer]] call CBA_fnc_serverEvent;
        };
    };
    case "chat_send": {
        private _cres = createHashMapFromArray [["error", ""]];
        private _targetIp = ((_data getOrDefault ["to", ""]) splitString ".") apply { parseNumber _x };
        private _ownIp = _computer getVariable ["AE3_network_address", [127, 0, 0, 1]];
        if (isNull _computer || {count _targetIp != 4}) then { _cres set ["error", "bad_addr"]; }
        else {
            // Loopback: messaging your own address (or 127.0.0.1) delivers to this same laptop.
            private _isLoopback = (_targetIp isEqualTo _ownIp) || {_targetIp isEqualTo [127, 0, 0, 1]};
            private _target = _computer;
            if (!_isLoopback) then { ([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"]; };
            // Reject ghost IPs: the route must resolve AND the resolved device must actually own
            // the requested address. A non-loopback send also requires a real (non-loopback) own IP.
            private _valid = !isNull _target
                && {_isLoopback || {(_target getVariable ["AE3_network_address", []]) isEqualTo _targetIp}}
                && {_isLoopback || {_ownIp isNotEqualTo [127, 0, 0, 1]}};
            if (_valid) then {
                private _senderIp = [_ownIp] call AE3_network_fnc_ip2str;
                private _dstIp = [_targetIp] call AE3_network_fnc_ip2str;
                ["ae3_network_imSend", [netId _target, netId _computer, _senderIp, _dstIp, _data getOrDefault ["text", ""]]] call CBA_fnc_serverEvent;
                _cres set ["ok", true];
            } else { _cres set ["error", "no_route"]; };
        };
        [_cres] call _reply;
    };

    // Router admin web page (#1/#3): view/edit the connected router's name/range/password.
    case "router_page": { [[_computer, "get", _data] call FUNC(routerHandle)] call _reply; };
    case "router_set":  { [[_computer, "set", _data] call FUNC(routerHandle)] call _reply; };

    // SSH access toggle for THIS device, set from Settings.
    case "ssh_config": {
        private _sres = createHashMapFromArray [["error", ""]];
        if (isNull _computer) then { _sres set ["error", "no_device"]; }
        else {
            [_computer, ["AE3_ssh_enabled", _data getOrDefault ["enabled", false], true]] remoteExecCall ["setVariable", 2];
            _sres set ["ok", true];
        };
        [_sres] call _reply;
    };

    // SSH client ops: connect + remote filesystem browse/copy. Resolve the target IP, then run
    // server-side (auth against the remote user list); the server replies async via ae3_desktop_sshReply.
    case "ssh_connect";
    case "ssh_ls";
    case "ssh_read";
    case "ssh_pull";
    case "ssh_push": {
        private _op = _command select [4]; // strip "ssh_"
        private _targetIp = ((_data getOrDefault ["to", ""]) splitString ".") apply { parseNumber _x };
        private _sres = createHashMapFromArray [["error", ""]];
        if (isNull _computer || {count _targetIp != 4}) exitWith { _sres set ["error", "bad_addr"]; [_sres] call _reply; };
        private _ownIp = _computer getVariable ["AE3_network_address", [127, 0, 0, 1]];
        private _isLoopback = (_targetIp isEqualTo _ownIp) || {_targetIp isEqualTo [127, 0, 0, 1]};
        private _target = _computer;
        if (!_isLoopback) then { ([_computer, _targetIp] call AE3_network_fnc_ping) params ["_target"]; };
        if (isNull _target || {!_isLoopback && {(_target getVariable ["AE3_network_address", []]) isNotEqualTo _targetIp}}) exitWith {
            _sres set ["error", "no_route"]; ["ssh_" + _op, _sres] call _reply;
        };
        ["ae3_desktop_sshOp", [clientOwner, _rid, netId _computer, netId _target,
            _data getOrDefault ["user", ""], _data getOrDefault ["pass", ""], _op, _data]] call CBA_fnc_serverEvent;
    };

    case "net_connect": {
        private _netId = _data getOrDefault ["netId", ""];
        if (_netId isNotEqualTo "" && {!isNull _computer}) then {
            private _router = objectFromNetId _netId;
            if (!isNull _router) then {
                // Pass the supplied wireless password + this client so the server can validate and
                // report success/failure back to the Network app.
                [_computer, _router, _data getOrDefault ["password", ""], clientOwner] remoteExec ["AE3_desktop_fnc_netConnectServer", 2];
            };
        };
    };

    case "net_disconnect": {
        if (!isNull _computer) then {
            [_computer] remoteExec ["AE3_desktop_fnc_netDisconnectServer", 2];
        };
    };

    // Open-window layout persistence: store the desktop's window snapshot on the laptop so a
    // reopen (by anyone) resumes exactly where it was left. Broadcast so it survives JIP/relocality.
    case "ui_save": {
        if (!isNull _computer) then {
            _computer setVariable [QGVAR(uiState), _data getOrDefault ["state", []], true];
        };
    };
    case "ui_get": {
        private _state = [];
        if (!isNull _computer) then { _state = _computer getVariable [QGVAR(uiState), []]; };
        [createHashMapFromArray [["state", _state]]] call _reply;
    };

    // Sign out: drop the session user; the JS side re-shows the login overlay. The display
    // (and the laptop claim/mutex) stay - this is a user switch, not a shutdown.
    case "signout": {
        _display setVariable [QGVAR(user), ""];
        // Clear the persisted session + window layout: only an explicit Sign Out locks the
        // laptop again and starts the next login with a clean desktop.
        if (!isNull _computer) then {
            _computer setVariable [QGVAR(sessionUser), "", true];
            _computer setVariable [QGVAR(uiState), [], true];
        };
    };

    // Shut down: close the desktop (the AE3_Desktop_BrowserDisplay onUnload restores the idle
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

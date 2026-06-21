#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Volume operations for the web desktop "My Computer" app (#11). Lists the system
 * volume plus every USB interface (connected drive + mount state), and mounts/unmounts drives via
 * the flashdrive backend (server-side). Mirrors how a real Debian/Ubuntu "Computer" view exposes
 * removable media.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 * 1: _user <STRING> - The logged-in session user (mount grants this user access)
 * 2: _op <STRING> - "list" | "mount" | "unmount"
 * 3: _data <HASHMAP> - key "interface" for mount/unmount
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]], ["_user", "", [""]], ["_op", "", [""]], ["_data", createHashMap, [createHashMap]]];

private _res = createHashMapFromArray [["error", ""]];
if (isNull _computer) exitWith { _res set ["error", "no_device"]; _res };

private _mountUser = ["root", _user] select (_user isNotEqualTo "" && {!(_user in ["root", "admin"])});

switch (_op) do {

    case "list": {
        private _vols = [
            createHashMapFromArray [["id", ""], ["label", "File System"], ["type", "system"], ["path", "/"], ["mounted", true]]
        ];
        private _interfaces = _computer getVariable ["AE3_USB_Interfaces", createHashMap];
        private _occupied = _computer getVariable ["AE3_USB_Interfaces_occupied", []];
        private _mounted = _computer getVariable ["AE3_USB_Interfaces_mounted", []];
        {
            _y params ["_index"];
            private _drive = _occupied param [_index, objNull];
            if (!isNull _drive) then {
                private _isMounted = _mounted param [_index, false];
                _vols pushBack createHashMapFromArray [
                    ["id", _x],
                    ["label", _drive getVariable ["ace_cargo_customName", "USB Drive"]],
                    ["type", "usb"],
                    ["path", format ["/mnt/%1", _x]],
                    ["mounted", _isMounted]
                ];
            };
        } forEach _interfaces;
        _res set ["volumes", _vols];
    };

    case "mount": {
        private _interface = _data getOrDefault ["interface", ""];
        if (_interface isEqualTo "") exitWith { _res set ["error", "bad_input"]; };
        [_computer, _interface, _mountUser] remoteExecCall ["AE3_flashdrive_fnc_mount", 2];
        _res set ["ok", true];
    };

    case "unmount": {
        private _interface = _data getOrDefault ["interface", ""];
        if (_interface isEqualTo "") exitWith { _res set ["error", "bad_input"]; };
        [_computer, _interface] remoteExecCall ["AE3_flashdrive_fnc_unmount", 2];
        _res set ["ok", true];
    };

    default { _res set ["error", "bad_op"]; };
};

_res

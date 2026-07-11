#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Volume operations for the web desktop "My Computer" app. Lists the system
 * volume plus every USB interface (connected drive + mount state), and mounts/unmounts drives via
 * the flashdrive backend (server-side). Mirrors how a real Debian/Ubuntu "Computer" view exposes
 * removable media.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The bound laptop
 * 1: _user <STRING> - The logged-in session user (mount grants this user access)
 * 2: _op <STRING> - "list" | "connect" | "mount" | "unmount"
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
        {
            _y params ["_index"];
            if (isNull (_occupied param [_index, objNull])) then {
                _vols pushBack createHashMapFromArray [["id", _x], ["label", format ["USB Slot %1", _x]], ["type", "free"], ["mounted", false]];
            };
        } forEach _interfaces;
        // Only real flash drives are connectable: use the same predicate as the ACE Connect menu
        // (direct parent Item_FlashDisk_AE3), which excludes laptop items and other ae3_vehicle carriers.
        // Identical drive classes are collapsed into a single entry carrying how many are held.
        private _driveClass = configFile >> "CfgWeapons" >> "Item_FlashDisk_AE3";
        private _available = [];
        private _seen = createHashMap;
        {
            private _item = _x;
            if (inheritsFrom (configFile >> "CfgWeapons" >> _item) isEqualTo _driveClass) then {
                private _index = _seen getOrDefault [_item, -1];
                if (_index < 0) then {
                    _available pushBack createHashMapFromArray [
                        ["item", _item],
                        ["label", getText (configFile >> "CfgWeapons" >> _item >> "displayName")],
                        ["count", 1]
                    ];
                    _seen set [_item, (count _available) - 1];
                } else {
                    private _entry = _available select _index;
                    _entry set ["count", (_entry getOrDefault ["count", 1]) + 1];
                };
            };
        } forEach (items player);
        _res set ["availableDrives", _available];
        _res set ["volumes", _vols];
    };

    case "connect": {
        private _interface = _data getOrDefault ["interface", ""];
        private _item = _data getOrDefault ["item", ""];
        private _interfaces = _computer getVariable ["AE3_USB_Interfaces", createHashMap];
        private _cfg = _interfaces getOrDefault [_interface, []];
        if (_interface isEqualTo "" || {_item isEqualTo ""} || {_cfg isEqualTo []}) exitWith { _res set ["error", "bad_input"]; };
        private _occupied = _computer getVariable ["AE3_USB_Interfaces_occupied", []];
        if !(((_occupied param [_cfg select 0, objNull]) isEqualTo objNull) && {_item in (items player)}) exitWith { _res set ["error", "unavailable"]; };
        [_computer, player, _item, _cfg] remoteExecCall ["AE3_flashdrive_fnc_connectFlashDrive", 2];
        _res set ["ok", true];
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

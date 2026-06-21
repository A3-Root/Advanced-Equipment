#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Ensures the system app-launcher catalog (/usr/share/applications/<id>.app) exists and
 * seeds a user's ~/Desktop with launcher symlinks, mirroring a real Ubuntu/Debian desktop. An
 * .app launcher is a plain file whose content is "app=<id>"; the web desktop reads it to launch the
 * matching app. Mission makers can copy/symlink any catalog launcher onto any user's Desktop to
 * curate per-user tooling (e.g. Root Cyberwarfare hacking tools). Idempotent.
 *
 * Arguments:
 * 0: _filesystem <ARRAY> - Filesystem object
 * 1: _home <STRING> - Absolute home path of the user (e.g. "/home/admin" or "/root")
 * 2: _owner <STRING> - The user who owns the Desktop and its seeded links
 *
 * Return Value:
 * None
 *
 * Example:
 * [_filesystem, "/home/admin", "admin"] call AE3_filesystem_fnc_seedDesktop;
 *
 * Public: No
 */

params ["_filesystem", "_home", "_owner"];

// Built-in apps that get a catalog launcher (Root Cyberwarfare adds its own at registration time).
private _catalog = ["files", "notepad", "calculator", "calendar", "browser", "mail", "messenger",
    "map", "settings", "network", "crypto", "crack", "snake", "recyclebin", "about", "mycomputer", "ssh"];
// Desktop now starts clean: only the fixed My Computer / File Explorer / Recycle Bin icons plus
// any user/API-created entries. Every app stays launchable from the Applications menu via the catalog.
// _legacySeed = the shortcuts older builds used to drop here; we migrate them away below.
private _legacySeed = ["files", "browser", "mail", "calculator"];

private _appPerms = [[true, true, true], [true, false, true]]; // rwx owner, r-x others

try {
    [[], _filesystem, "/usr/share/applications", "root", "root", _appPerms] call AE3_filesystem_fnc_ensureDir;
    {
        private _p = "/usr/share/applications/" + _x + ".app";
        if !([[], _filesystem, _p, "root"] call AE3_filesystem_fnc_fsObjExists) then {
            [[], _filesystem, _p, "app=" + _x, "root", "root", _appPerms] call AE3_filesystem_fnc_createFile;
        };
    } forEach _catalog;

    [[], _filesystem, _home + "/Desktop", "root", _owner, _appPerms] call AE3_filesystem_fnc_ensureDir;

    // Remove the formerly-seeded shortcuts, but only when they are still the untouched seeded symlink
    // pointing at the catalog launcher - user-created or renamed files are left alone.
    {
        private _link = _home + "/Desktop/" + _x + ".app";
        if ([[], _filesystem, _link, "root"] call AE3_filesystem_fnc_fsObjExists) then {
            private _catalogPath = "/usr/share/applications/" + _x + ".app";
            try {
                private _obj = [(_link splitString "/"), _filesystem] call AE3_filesystem_fnc_resolvePntr;
                if (([(_obj select 0)] call AE3_filesystem_fnc_symlinkTarget) isEqualTo _catalogPath) then {
                    [[], _filesystem, _link, "root"] call AE3_filesystem_fnc_delObj;
                };
            } catch {};
        };
    } forEach _legacySeed;
} catch {
    WARNING_1("seedDesktop failed: %1",_exception);
};

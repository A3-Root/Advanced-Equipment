// File: fnc_registerExtApp.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers an external application into the web desktop launcher, so other addons
 * (e.g. Root Cyberwarfare) can add apps without AE3 depending on them. Registered apps are pushed
 * to the browser on boot and rendered as a generic device-list app (parameterised by "kind"),
 * which talks back through registered commands (see AE3_desktop_fnc_registerCmd). Call at postInit
 * on clients (hasInterface).
 *
 * Arguments:
 * 0: _id <STRING> - Unique app id
 * 1: _title <STRING> - Display name
 * 2: _glyph <STRING> - Emoji/glyph icon
 * 3: _kind <STRING> - App template; currently "deviceList"
 * 4: _extra <HASHMAP> (Optional) - Extra params forwarded to the JS app (e.g. deviceType)
 *    Optional key: requiresVar [varName, expectedValue] filters the app per laptop.
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_title", "", [""]], ["_glyph", "", [""]], ["_kind", "deviceList", [""]], ["_extra", createHashMap, [createHashMap]]];

if (_id isEqualTo "") exitWith {};

private _apps = missionNamespace getVariable [QGVAR(extApps), []];
_apps = _apps select { (_x getOrDefault ["id", ""]) isNotEqualTo _id };
_apps pushBack createHashMapFromArray [
    ["id", _id], ["title", _title], ["glyph", _glyph], ["kind", _kind], ["extra", _extra]
];
missionNamespace setVariable [QGVAR(extApps), _apps];

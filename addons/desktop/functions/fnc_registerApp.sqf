#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a desktop application at runtime (alternative to a CfgAE3Apps config
 * entry). The entry function is called as [_winId, _ctrlGroup, _computer, _args] and may return
 * a HASHMAP with optional "onClose" CODE callback. Local effect - call on all clients that
 * should see the app (e.g. from your addon's XEH_preInit).
 *
 * Arguments:
 * 0: _className <STRING> - Unique app id
 * 1: _displayName <STRING> - Name shown on the desktop icon
 * 2: _entry <STRING> - Function name (resolved via missionNamespace)
 * 3: _size <ARRAY> (Optional, default: [0.5, 0.5]) - Window size as fraction of the desktop
 * 4: _showOnDesktop <BOOL> (Optional, default: true)
 * 5: _singleton <BOOL> (Optional, default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["myMod_hackTool", "Hack Tool", "myMod_fnc_hackToolApp", [0.6, 0.6]] call AE3_desktop_fnc_registerApp;
 *
 * Public: Yes
 */

params ["_className", "_displayName", "_entry", ["_size", [0.5, 0.5]], ["_showOnDesktop", true], ["_singleton", true]];

private _apps = missionNamespace getVariable ["ae3_desktop_runtimeApps", []];

// Re-registration replaces the previous entry
_apps = _apps select { (_x select 0) isNotEqualTo _className };
_apps pushBack [_className, _displayName, _entry, _size param [0, 0.5], _size param [1, 0.5], _showOnDesktop, _singleton];

missionNamespace setVariable ["ae3_desktop_runtimeApps", _apps];

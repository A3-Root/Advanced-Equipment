#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Server-side setter for the per-laptop system name (hostname) and desktop wallpaper,
 * driven by the web Settings app or a Zeus module (#15). Both values are broadcast so the terminal
 * prompt, the web Settings/System panel and every client's desktop stay in sync. Empty values are
 * left unchanged so callers can set just one. Must run on the server.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The laptop
 * 1: _hostname <STRING> (Optional, default: "") - New system name ("" = unchanged)
 * 2: _wallpaper <STRING> (Optional, default: "") - CSS background or image path ("" = unchanged)
 *
 * Return Value:
 * Success <BOOL>
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]], ["_hostname", "", [""]], ["_wallpaper", "", [""]]];

if (!isServer) exitWith { false };
if (isNull _computer) exitWith { false };

if (_hostname isNotEqualTo "") then {
    _computer setVariable ["ace_cargo_customName", _hostname, true];
};
if (_wallpaper isNotEqualTo "") then {
    _computer setVariable ["AE3_desktop_wallpaper", _wallpaper, true];
};

true

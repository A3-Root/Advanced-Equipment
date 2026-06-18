#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: R1 spike (WS-B) - opens the fullscreen CEF web-browser desktop and loads the
 * HTML/JS UI. This is the foundation of the os-master-style GUI port; it is intentionally
 * standalone so the existing native desktop (AE3_desktop_fnc_desktop_open) keeps working until
 * the web port reaches parity. Loads ui\web\index.html into a type-106 browser control and
 * routes JS->SQF messages through AE3_desktop_fnc_jsRouter. Client-only.
 *
 * Arguments:
 * 0: _computer <OBJECT> (Optional, default: objNull) - The laptop this session is bound to
 *
 * Return Value:
 * The created display <DISPLAY>
 *
 * Example:
 * [_laptop] call AE3_desktop_fnc_desktop_openWeb;
 *
 * Public: No
 */

params [["_computer", objNull, [objNull]]];

if (!hasInterface) exitWith { displayNull };

// Convenience for debug-console testing: bind the AE3 device under the cursor if none given.
if (isNull _computer) then {
    private _cur = cursorObject;
    if (!isNull _cur && {isClass (configOf _cur >> "AE3_Device")}) then { _computer = _cur; };
};

private _display = (findDisplay 46) createDisplay "AE3_Desktop_BrowserDisplay";
if (isNull _display) exitWith { displayNull };

_display setVariable [QGVAR(computer), _computer];

// Pull the authoritative filesystem onto the laptop object (object-as-namespace), as the native
// desktop does. getRemoteVar self-spawns into a scheduled environment; the Files/Notepad apps
// read the cached copy and push mutations back via setVariable. AE3_Userlist is already broadcast.
if (!isNull _computer && isMultiplayer) then {
    [_computer, "AE3_filesystem"] call AE3_main_fnc_getRemoteVar;
    [_computer, "AE3_filepointer"] call AE3_main_fnc_getRemoteVar;
};

// Claim the laptop and show the static "in use" screen for other players (mirrors native open).
if (!isNull _computer) then {
    _computer setVariable ["AE3_computer_mutex", player, true];
    _computer setObjectTextureGlobal [1, "#(argb,8,8,3)color(0.05,0.08,0.12,1,co)"];
    [_computer, "inUse", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
};

private _ctrl = _display displayCtrl 1337;
[_ctrl, ["LoadFile", "\z\ae3\addons\desktop\ui\web\index.html"]] call FUNC(browserAction);

// "JSDialog" (Arma 2.18+) is newer than HEMTT's event list; pass it as a variable so the
// unknown-event lint does not fire on a literal it cannot validate.
private _jsDialogEvent = "JSDialog";
_ctrl ctrlAddEventHandler [_jsDialogEvent, { _this call FUNC(jsRouter) }];

// Keep a handle so SQF->JS pushes (ExecJS) can find the live browser control.
uiNamespace setVariable [QGVAR(browserCtrl), _ctrl];

// ESC closes the spike display (fullscreen browser captures most other input).
_display displayAddEventHandler ["KeyDown", {
    params ["_dsp", "_key"];
    if (_key == 1) exitWith { _dsp closeDisplay 0; true }; // DIK_ESCAPE
    false
}];

_display

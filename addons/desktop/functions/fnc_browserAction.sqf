#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Single wrapper around the engine command ctrlWebBrowserAction (Arma 2.18+).
 * HEMTT's bundled SQF parser predates that command and cannot parse a direct call to it (SPE2),
 * so the call is isolated here behind a one-time compiled closure (kept out of the parser via a
 * string literal). Every web-desktop SQF<->browser interaction (LoadFile, ExecJS, OpenDevConsole,
 * ...) goes through this function so the unparseable command lives in exactly one place. The
 * closure is compiled once per client and cached in uiNamespace. Client-only.
 *
 * Arguments:
 * 0: _ctrl <CONTROL> - The type-106 browser control
 * 1: _action <ARRAY> - The ctrlWebBrowserAction argument array, e.g. ["LoadFile", _path] or ["ExecJS", _js]
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ctrl, ["LoadFile", "\z\ae3\addons\desktop\ui\web\index.html"]] call AE3_desktop_fnc_browserAction;
 *
 * Public: No
 */

params [["_ctrl", controlNull, [controlNull]], ["_action", [], [[]]]];

if (isNull _ctrl) exitWith {};
if (_action isEqualTo []) exitWith {};

private _fn = uiNamespace getVariable [QGVAR(browserActionFn), {}];
if (_fn isEqualTo {}) then {
    // String literal: hidden from HEMTT's SQF parser, which cannot parse ctrlWebBrowserAction.
    _fn = compile "params ['_c', '_a']; _c ctrlWebBrowserAction _a";
    uiNamespace setVariable [QGVAR(browserActionFn), _fn];
};

[_ctrl, _action] call _fn;

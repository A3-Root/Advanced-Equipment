#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Map" app: interactive mission map (RscMapControl) centered on the
 * laptop's position. Markers/zoom follow the standard map control behavior.
 *
 * Arguments:
 * 0: _winId <NUMBER>
 * 1: _ctrlGroup <CONTROL>
 * 2: _computer <OBJECT>
 * 3: _args <ANY>
 *
 * Return Value:
 * App callbacks <HASHMAP>
 *
 * Public: No
 */

params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

private _mapCtrl = _display ctrlCreate ["RscMapControl", -1, _ctrlGroup];
_mapCtrl ctrlSetPosition [0.01, 0.045, _w - 0.02, _h - 0.055];
_mapCtrl ctrlCommit 0;

_mapCtrl ctrlMapAnimAdd [0, 0.1, getPos _computer];
ctrlMapAnimCommit _mapCtrl;

createHashMap

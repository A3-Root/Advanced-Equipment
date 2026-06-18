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
private _theme = _session getOrDefault ["theme", createHashMap];

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

// Recenter button: guarantees the user can always return to the laptop's position even if
// they pan the map far away (previously there was no way to recover an off-centre map).
private _recenterBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_recenterBtn ctrlSetPosition [0.01, 0.045, 0.14, 0.035];
_recenterBtn ctrlSetText (localize "STR_AE3_Desktop_Map_Recenter");
_recenterBtn ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.2, 0.5, 0.8, 1]]);
_recenterBtn ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
_recenterBtn ctrlCommit 0;

private _mapCtrl = _display ctrlCreate ["RscMapControl", -1, _ctrlGroup];
_mapCtrl ctrlSetPosition [0.01, 0.085, _w - 0.02, _h - 0.095];
_mapCtrl ctrlEnable true;
_mapCtrl ctrlCommit 0;

// Reasonable starting zoom centred on the laptop (0.1 was far too tight).
_mapCtrl ctrlMapAnimAdd [0, 0.4, getPosWorld _computer];
ctrlMapAnimCommit _mapCtrl;

_recenterBtn setVariable ["AE3_mapCtrl", _mapCtrl];
_recenterBtn setVariable ["AE3_computer", _computer];
_recenterBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_ctrl"];
	private _map = _ctrl getVariable "AE3_mapCtrl";
	private _comp = _ctrl getVariable "AE3_computer";
	_map ctrlMapAnimAdd [0.3, 0.4, getPosWorld _comp];
	ctrlMapAnimCommit _map;
}];

createHashMap

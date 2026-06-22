/*
 * Author: Root
 * Description: Apply handler for the router configuration dialog. Reads the fields and applies
 * them to the target router server-side (broadcast) via AE3_network_fnc_applyRouterConfig, then
 * closes the dialog. Bound to the dialog's Apply button. Client-only.
 *
 * Arguments:
 * 0: _ctrl <CONTROL> - The Apply button (passed by onButtonClick)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_ctrl"];

private _dlg = ctrlParent _ctrl;
if (isNull _dlg) exitWith {};

private _router = uiNamespace getVariable ["AE3_router_configTarget", objNull];
if (isNull _router) exitWith { _dlg closeDisplay 0; };

private _name = ctrlText (_dlg displayCtrl 17031);
private _range = parseNumber (ctrlText (_dlg displayCtrl 17032));
private _pass = ctrlText (_dlg displayCtrl 17033);
private _gateway = ctrlText (_dlg displayCtrl 17034);

[_router, _name, _range, _pass, _gateway] remoteExecCall ["AE3_network_fnc_applyRouterConfig", 2];

_dlg closeDisplay 1;

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Eden/Zeus module handler for AE3_AddWebsite. Registers a custom domain -> mission
 * site-root mapping (AE3_desktop_fnc_registerSite) so the Browser can visit the domain and load that
 * folder's index.html. Eden/trigger placement reads the module's Domain/SiteRoot attributes; curator
 * placement with Zeus Enhanced opens a ZEN dialog on the placing curator instead.
 *
 * Arguments:
 * 0: _module <OBJECT>
 * 1: _units <ARRAY>
 * 2: _activated <BOOL>
 *
 * Return Value:
 * true <BOOL>
 *
 * Public: No
 */

params ["_module", "_units", "_activated"];

if (!isServer) exitWith {};
if (!_activated) exitWith { true };

// Zeus + ZEN: gather domain + site root through a ZEN dialog on the curator's machine.
if ((_module getVariable ["BIS_fnc_moduleInit_isCuratorPlaced", false]) && EGVAR(main,hasZenDialog)) exitWith
{
    [netId _module] remoteExec [QFUNC(zen_module_addWebsite), owner _module];
    true
};

// Eden / trigger (or Zeus without ZEN): read the configured attributes.
private _domain = _module getVariable ["AE3_ModuleWebsite_Domain", ""];
private _siteRoot = _module getVariable ["AE3_ModuleWebsite_SiteRoot", ""];
if (_domain isNotEqualTo "" && {_siteRoot isNotEqualTo ""}) then
{
    [_domain, _siteRoot] call AE3_desktop_fnc_registerSite;
};

deleteVehicle _module;
true

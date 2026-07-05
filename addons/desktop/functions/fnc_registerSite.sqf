#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Registers a custom domain -> mission site-root mapping for the desktop Browser app.
 * Visiting the domain (e.g. "thisisme.com") loads <siteRoot>/index.html and routes the page's links
 * under that domain (e.g. "thisisme.com/about" -> <siteRoot>/about). Global calls publish a
 * mission-wide domain; targeted calls publish it only on the selected laptops. Mirrors
 * AE3_desktop_fnc_registerWebpage. Site content is served through A3.loadFile, so the site root is a
 * mission-relative folder (mission root is searched before the mod PBO).
 *
 * Arguments:
 * 0: _domain <STRING> - The domain, e.g. "thisisme.com"
 * 1: _siteRoot <STRING> - Mission-relative folder holding index.html, e.g. "sites/portal"
 * 2: _targets <OBJECT|ARRAY|STRING> (Optional, default: "all") - Laptop targets or "all"
 *
 * Return Value:
 * None
 *
 * Example:
 * ["thisisme.com", "sites/portal"] call AE3_desktop_fnc_registerSite;
 *
 * Public: Yes
 */

params ["_domain", "_siteRoot", ["_targets", "all"]];

if (!isServer) exitWith
{
    private _targetArg = if (_targets isEqualType objNull) then { netId _targets } else { _targets };
    ["ae3_desktop_registerSite", [_domain, _siteRoot, _targetArg]] call CBA_fnc_serverEvent;
};

private _key = toLower (trim _domain);
if (_key isEqualTo "") exitWith {};

// Normalise the site root to a folder: forward slashes, no trailing slash, drop a trailing index.html.
_siteRoot = (trim _siteRoot) splitString "\" joinString "/";
_siteRoot = _siteRoot regexReplace ["/+$", ""];
private _low = toLower _siteRoot;
if ((count _siteRoot >= 11) && {(_low find "/index.html") isEqualTo (count _siteRoot - 11)}) then
{
    _siteRoot = _siteRoot select [0, count _siteRoot - 11];
};

if (_targets isEqualTo "all") then
{
    private _sites = missionNamespace getVariable ["AE3_Desktop_Sites", createHashMap];
    _sites set [_key, _siteRoot];
    missionNamespace setVariable ["AE3_Desktop_Sites", _sites, true];
}
else
{
    private _computers = switch (true) do
    {
        case (_targets isEqualType objNull): { [_targets] };
        case (_targets isEqualType []): { _targets };
        default { [objectFromNetId _targets] };
    };

    {
        if (!isNull _x) then
        {
            private _sites = _x getVariable ["AE3_Desktop_Sites", createHashMap];
            _sites set [_key, _siteRoot];
            _x setVariable ["AE3_Desktop_Sites", _sites, true];
        };
    } forEach _computers;
};

INFO_2("Registered site %1 -> %2",_key,_siteRoot);

// Nudge any open Browser to re-pull its site list so the new domain resolves without reopening.
["ae3_desktop_webChanged", []] call CBA_fnc_globalEvent;

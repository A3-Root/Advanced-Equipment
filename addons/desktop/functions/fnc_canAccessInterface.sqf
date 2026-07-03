#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Framework hook: decides whether a player may open a given interface (CLI or
 * GUI) on a laptop. Two layers, both mission-maker controlled:
 *
 * 1. The laptop's interface mode ("cli", "gui" or "both" - AE3_interfaceMode object variable,
 *    set via the 3DEN attribute, AE3_desktop_fnc_setInterfaceMode or directly).
 * 2. An optional per-interface access condition on the laptop:
 *      AE3_cliAccessCondition / AE3_guiAccessCondition
 *    Either CODE ([_laptop, _player] -> BOOL) or an ARRAY of player UIDs and/or sides
 *    (set via AE3_desktop_fnc_setInterfaceAccess or directly with setVariable).
 *
 * Other mods can build their own access models on top by setting these variables
 * (e.g. keycard items, hacking states, rank checks).
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The laptop
 * 1: _player <OBJECT> - The player asking for access
 * 2: _iface <STRING> - "cli" or "gui"
 *
 * Return Value:
 * Whether access is allowed <BOOL>
 *
 * Example:
 * if ([_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface) then { ... };
 *
 * Public: Yes
 */

params ["_laptop", "_player", "_iface"];

if (isNull _laptop || isNull _player) exitWith { false };
if (!(_iface in ["cli", "gui"])) exitWith { false };

private _mode = _laptop getVariable ["AE3_interfaceMode", missionNamespace getVariable ["AE3_Desktop_DefaultMode", "cli"]];

if (!(_mode in [_iface, "both"])) exitWith { false };

private _condition = _laptop getVariable [format ["AE3_%1AccessCondition", _iface], {true}];

// ARRAY sugar: list of player UIDs and/or sides
if (_condition isEqualType []) exitWith
{
	((getPlayerUID _player) in _condition) || {(side group _player) in _condition}
};

if (!(_condition isEqualType {})) exitWith { true };

// Evaluate the mission-maker-supplied condition defensively: this runs inside the ACE interaction
// hover condition, where a thrown error would disable the whole interaction menu. A malformed or
// non-boolean result is treated as "no access" rather than allowed to propagate.
private _result = false;
try
{
	_result = [_laptop, _player] call _condition;
	if (!(_result isEqualType false)) then { _result = false };
}
catch
{
	_result = false;
};

_result

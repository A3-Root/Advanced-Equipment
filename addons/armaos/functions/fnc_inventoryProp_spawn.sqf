#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Spawns the world stand-in model shown while a laptop is used straight from the
 * inventory. Creates the laptop's non-AE3 base class (same model, but without the AE3 filesystem,
 * power and terminal initialisation), so the prop is a plain networked object every nearby and
 * late-joining player sees, with no interactions of its own. Simulation is disabled and the prop is
 * attached to the operator. The created object is stored on the laptop so it can be removed later.
 * Runs on the server.
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The (hidden) laptop object driving the session
 * 1: _player <OBJECT> - The operator the model is attached to
 *
 * Return Value:
 * None
 *
 * Example:
 * [_laptop, _player] remoteExec ["AE3_armaos_fnc_inventoryProp_spawn", 2];
 *
 * Public: No
 */

params ["_laptop", "_player"];

if (!isServer) exitWith {};
if (isNull _laptop || {isNull _player}) exitWith {};

// Remove any stale stand-in first (e.g. a session that ended uncleanly).
private _old = _laptop getVariable ["AE3_armaos_invProp", objNull];
if (!isNull _old) then { detach _old; deleteVehicle _old; };

// The AE3 laptop class inherits from a vanilla base with the same model but none of the AE3 init
// event handlers, so creating the base yields a plain prop instead of a second functional laptop.
private _baseClass = configName (inheritsFrom (configOf _laptop));
if (_baseClass isEqualTo "") exitWith {};

private _prop = createVehicle [_baseClass, getPosATL _player, [], 0, "CAN_COLLIDE"];
_prop enableSimulationGlobal false;
_prop attachTo [_player, [0, 0.5, 0.5]];

_laptop setVariable ["AE3_armaos_invProp", _prop, true];

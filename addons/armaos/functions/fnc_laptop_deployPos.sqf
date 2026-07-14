// File: fnc_laptop_deployPos.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Works out where a laptop deployed by a player should actually stand: on the first solid
 * surface under the spot in front of them. Terrain height is not the same thing as the floor a player is
 * standing on - inside a building it can be a storey or more below - so a position taken at ground level
 * leaves the laptop hanging in the air to fall, and a fall inside a building can end on a roof or through
 * it. The surface is found by looking straight down from head height in front of the player, which lands
 * the laptop on the floor of the room they are in, on the deck they are on, or on the terrain when there
 * is nothing else beneath them.
 *
 * Arguments:
 * 0: _player <OBJECT> - The player deploying the laptop
 *
 * Return Value:
 * Position <ARRAY> - Deployment position in ATL, resting on the surface in front of the player. ATL is
 *                    what createVehicle and setPosATL expect of a laptop, so it is what is handed back.
 *
 * Example:
 * private _pos = [player] call AE3_armaos_fnc_laptop_deployPos;
 *
 * Public: No
 */

params ["_player"];

// A metre and a half in front, from above the player's head down to below their feet: the span a floor
// they could deploy onto has to lie within.
private _from = AGLToASL (_player modelToWorld [0, 1.5, 1.8]);
private _to = AGLToASL (_player modelToWorld [0, 1.5, -1.0]);

// Buildings, terrain and objects all count as something to stand on; the player themselves does not.
private _surfaces = lineIntersectsSurfaces [_from, _to, _player, objNull, true, 1, "GEOM", "FIRE"];

private _posASL = if (_surfaces isEqualTo []) then {
    // Nothing solid in front of the player - a doorway over a drop, a pier - so the laptop is put down at
    // the player's own feet, which is a surface they are demonstrably standing on.
    AGLToASL (_player modelToWorld [0, 1.5, 0])
} else {
    +((_surfaces select 0) select 0)
};

// Clear of the surface by a hair, so the laptop rests on it rather than starting inside it.
_posASL set [2, (_posASL select 2) + 0.05];

ASLToATL _posASL

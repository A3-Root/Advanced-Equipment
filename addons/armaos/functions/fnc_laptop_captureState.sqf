#include "..\script_component.hpp"
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Captures a laptop's complete persistent state into a standalone HashMap: every
 * serializable object variable (filesystem, user list, calendar events, mail, network config,
 * messaging handles, etc) except the runtime/TEXT/CODE variables listed by
 * AE3_armaos_fnc_laptop_stateVarsExcluded. The result can be re-applied to another laptop with
 * AE3_armaos_fnc_laptop_applyState. Used by the Save Laptop Zeus module.
 *
 * Arguments:
 * 0: _laptop <OBJECT> - The laptop to snapshot
 *
 * Return Value:
 * State snapshot <HASHMAP>
 *
 * Example:
 * private _state = [_laptop] call AE3_armaos_fnc_laptop_captureState;
 *
 * Public: No
 */

params ["_laptop"];

private _excluded = call AE3_armaos_fnc_laptop_stateVarsExcluded;
private _state = createHashMap;

{
    if !(_x in _excluded) then {
        private _value = _laptop getVariable _x;
        if (!isNil "_value") then {
            _state set [_x, _value];
        };
    };
} forEach (allVariables _laptop);

// Remember the source class so a restore can sanity-check it is being applied to a compatible model.
_state set ["AE3_OBJECT_TYPE", typeOf _laptop];

_state

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Checks whether an entity has a specific AE3 capability. Capability flags are set
 * (server-side, public) during device initialization, so mission makers and dependent mods no
 * longer need ad-hoc getVariable probing to identify device types.
 *
 * Available capabilities:
 * "hasTerminal"     - runs ArmaOS (computer with terminal)
 * "hasFilesystem"   - has a virtual filesystem (computers, flash drives)
 * "isNetworkClient" - participates in the AE3 network as a client
 * "isRouter"        - acts as a network router
 * "hasUsb"          - has USB interfaces for flash drives
 * "hasBattery"      - has a battery (internal or battery pack)
 * "hasFuelTank"     - has a fuel tank (generators)
 *
 * Arguments:
 * 0: _entity <OBJECT> - Entity to check
 * 1: _capability <STRING> - Capability name (see list above)
 *
 * Return Value:
 * Whether the entity has the capability <BOOL>
 *
 * Example:
 * if ([_object, "hasTerminal"] call AE3_main_fnc_hasCapability) then { ... };
 *
 * Public: Yes
 */

params ["_entity", "_capability"];

if (isNull _entity) exitWith { false };

_entity getVariable [format ["AE3_cap_%1", _capability], false]

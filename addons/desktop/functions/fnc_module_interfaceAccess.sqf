// File: fnc_module_interfaceAccess.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Placeholder module function for AE3_InterfaceAccess. The module is Zeus-only
 * and does all its work through the curator dialog (fnc_zeus_module_interfaceAccess), so the
 * trigger/Eden path is intentionally a no-op.
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

// All handling is in the curator dialog; nothing to do here.
true

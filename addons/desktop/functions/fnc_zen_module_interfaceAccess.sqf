#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Interface & Access module. Opens a ZEN Dynamic Dialog
 * on the curator's machine: the laptop's interface mode plus two ZEN OWNERS pickers (who may use the CLI,
 * who may use the GUI). OWNERS scales cleanly to large lobbies where a per-player combo list would not
 * fit. On confirm it flattens each OWNERS selection to a list of player UIDs + sides and applies it via
 * the same appliers as the legacy dialog (AE3_desktop_fnc_setInterfaceMode / _setInterfaceAccess). An
 * empty picker leaves that interface open to everyone (subject to the mode). Owns the module lifecycle.
 *
 * Arguments:
 * 0: _module <OBJECT> - The module logic
 * 1: _computer <OBJECT> - The target laptop
 *
 * Return Value:
 * None
 *
 * Example:
 * [_module, _laptop] call AE3_desktop_fnc_zen_module_interfaceAccess;
 *
 * Public: No
 */

params ["_module", "_computer"];

private _rows = [
    ["COMBO", localize "STR_AE3_Desktop_Access_ModeDefault", [
        ["default", "cli", "gui", "both"],
        [
            localize "STR_AE3_Desktop_Access_ModeDefault",
            localize "STR_AE3_Desktop_Access_CLI",
            localize "STR_AE3_Desktop_Access_GUI",
            localize "STR_AE3_Desktop_Access_Both"
        ],
        3
    ]],
    // Empty = everyone (with the mode) may use that interface; add owners to restrict it.
    ["OWNERS", ["CLI access (empty = everyone)", "Who may use the terminal (CLI)"], [[], [], [], 2]],
    ["OWNERS", ["GUI access (empty = everyone)", "Who may use the desktop (GUI)"], [[], [], [], 2]]
];

private _onConfirm = {
    params ["_values", "_args"];
    _values params ["_mode", "_cliOwners", "_guiOwners"];
    _args params ["_module", "_computer"];

    // Flatten a ZEN OWNERS result [sides, groups, players, tab] to an array of player UID strings plus
    // side objects, which AE3_desktop_fnc_setInterfaceAccess accepts directly (matched by
    // AE3_desktop_fnc_canAccessInterface's array branch: UID or side membership).
    private _fnc_flat = {
        params ["_owners"];
        _owners params ["_sides", "_groups", "_players", "_tab"];
        private _out = [];
        { _out pushBack getPlayerUID _x; } forEach _players;
        private _grpUnits = [];
        { _grpUnits append (units _x); } forEach _groups;
        { if (isPlayer _x) then { _out pushBack getPlayerUID _x; }; } forEach _grpUnits;
        { _out pushBack _x; } forEach _sides; // side objects
        _out
    };

    private _cli = [_cliOwners] call _fnc_flat;
    private _gui = [_guiOwners] call _fnc_flat;

    if (_mode isNotEqualTo "default") then
    {
        [_computer, _mode] call FUNC(setInterfaceMode);
    };

    // Empty selection -> reset to allow-all ({true}); otherwise restrict to the listed owners.
    [_computer, "cli", ([{true}, _cli] select (_cli isNotEqualTo []))] call FUNC(setInterfaceAccess);
    [_computer, "gui", ([{true}, _gui] select (_gui isNotEqualTo []))] call FUNC(setInterfaceAccess);

    [localize "STR_AE3_Desktop_Config_InterfaceAccessDisplayName", format ["%1: %2", localize "STR_AE3_Desktop_Access_Applied", [_computer] call FUNC(deviceLabel)], 5] call BIS_fnc_curatorHint;

    deleteVehicle _module;
};

private _onCancel = {
    params ["_values", "_args"];
    deleteVehicle (_args select 0);
};

[
    "STR_AE3_Desktop_Config_InterfaceAccessDisplayName",
    _rows,
    _onConfirm,
    _onCancel,
    [_module, _computer]
] call EFUNC(main,zen_createDialog);

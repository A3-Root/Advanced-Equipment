#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Zeus Enhanced dialog variant of the Interface & Access module. Opens a ZEN Dynamic Dialog
 * on the curator's machine with the laptop's interface mode, one access combo per connected player and a
 * per-side fallback. On confirm it reuses the same access-condition builder and appliers as the legacy
 * dialog (AE3_desktop_fnc_setInterfaceMode / _setInterfaceAccess). Owns the module lifecycle.
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

private _accessValues = ["none", "cli", "gui", "both"];
private _accessLabels = [
    localize "STR_AE3_Desktop_Access_None",
    localize "STR_AE3_Desktop_Access_CLI",
    localize "STR_AE3_Desktop_Access_GUI",
    localize "STR_AE3_Desktop_Access_Both"
];

// Interface mode row (default = Both, i.e. leave the global default in place)
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
    ]]
];

// One access combo per connected human (default Both); track UIDs so the values map back on confirm.
private _uids = [];
{
    private _uid = getPlayerUID _x;
    if (_uid isEqualTo "") then { continue };
    _uids pushBack _uid;
    _rows pushBack ["COMBO", name _x, [_accessValues, _accessLabels, 3]];
} forEach (allPlayers - entities "HeadlessClient_F");

// Per-side fallback combos (WEST/EAST/GUER/CIV), default Both
{
    _rows pushBack ["COMBO", _x, [_accessValues, _accessLabels, 3]];
} forEach ["Side: WEST", "Side: EAST", "Side: GUER", "Side: CIV"];

private _onConfirm = {
    params ["_values", "_args"];
    _args params ["_module", "_computer", "_uids"];

    private _mode = _values select 0;
    private _nPlayers = count _uids;
    private _playerAccess = _values select [1, _nPlayers];
    private _sideVals = _values select [1 + _nPlayers, 4];

    // Interface mode
    if (_mode isNotEqualTo "default") then
    {
        [_computer, _mode] call FUNC(setInterfaceMode);
    };

    private _playerPairs = [];
    {
        _playerPairs pushBack [_x, _playerAccess select _forEachIndex];
    } forEach _uids;

    private _sidePairs = [
        ["WEST", _sideVals select 0],
        ["EAST", _sideVals select 1],
        ["GUER", _sideVals select 2],
        ["CIV",  _sideVals select 3]
    ];

    // Authoritative per-player, then per-side fallback. Compiled with the tables inlined so the
    // condition is self-contained (setInterfaceAccess stores it as a public, JIP-safe var).
    private _mkCond = {
        params ["_iface"];
        compile format [
            "params ['_l', '_p']; private _pa = %1; private _sa = %2; private _ic = %3; private _u = getPlayerUID _p; private _a = ''; { if ((_x select 0) isEqualTo _u) exitWith { _a = _x select 1 } } forEach _pa; if (_a isEqualTo '') then { private _sn = str (side group _p); { if ((_x select 0) isEqualTo _sn) exitWith { _a = _x select 1 } } forEach _sa }; _a in _ic",
            str _playerPairs, str _sidePairs, str [_iface, "both"]
        ]
    };

    [_computer, "cli", ["cli"] call _mkCond] call FUNC(setInterfaceAccess);
    [_computer, "gui", ["gui"] call _mkCond] call FUNC(setInterfaceAccess);

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
    [_module, _computer, _uids]
] call EFUNC(main,zen_createDialog);

#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Web-desktop backend for the Cryptography > Crack app. Cryptanalysis of caesar/columnar
 * ciphered text (bruteforce / statistics / key-length), mirroring the CLI `crack` command but
 * returning result lines to the browser instead of the terminal. Pure computation.
 *
 * Arguments:
 * 0: _data <HASHMAP> - {mode:"bruteforce"|"statistics"|"key", algorithm:"caesar"|"columnar", text:STRING}
 *
 * Return Value:
 * Result <HASHMAP> - {error:STRING, lines:ARRAY<STRING>}
 *
 * Public: No
 */

params [["_data", createHashMap, [createHashMap]]];

private _mode = _data getOrDefault ["mode", "bruteforce"];
private _algo = _data getOrDefault ["algorithm", "caesar"];
private _text = _data getOrDefault ["text", ""];

private _res = createHashMapFromArray [["error", ""], ["lines", []]];
if (_text isEqualTo "") exitWith { _res set ["error", "no_input"]; _res };

private _lines = [];
private _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

switch (_algo) do {
    case "caesar": {
        if (_mode isEqualTo "key") then { _res set ["error", "unsupported"]; }
        else {
            private _msg = [toUpper _text, _alphabet + " "] call BIS_fnc_filterString;
            if (_mode isEqualTo "bruteforce") then {
                for "_i" from 1 to (count _alphabet) do {
                    _lines pushBack format ["key %1: %2", _i, [_i, "decrypt", _msg] call AE3_armaos_fnc_encryption_caesar];
                };
            };
            if (_mode isEqualTo "statistics") then {
                private _stats = createHashMap;
                {
                    if (_x isNotEqualTo " ") then { _stats set [_x, (_stats getOrDefault [_x, 0]) + 1]; };
                } forEach (_msg splitString "");
                private _chars = keys _stats; _chars sort true;
                private _idxE = _alphabet find "E";
                {
                    private _kIfE = ((( _alphabet find _x) + (count _alphabet)) - _idxE) % (count _alphabet);
                    _lines pushBack format ["'%1' x%2 -> possible key %3", _x, _stats get _x, _kIfE];
                } forEach _chars;
            };
        };
    };
    case "columnar": {
        if (_mode isEqualTo "statistics") then { _res set ["error", "unsupported"]; }
        else {
            private _msgLen = count _text;
            private _keyLengths = [];
            for "_i" from 2 to (_msgLen - 1) do { if ((_msgLen mod _i) == 0) then { _keyLengths pushBack _i; }; };
            if (_keyLengths isEqualTo []) then { _res set ["error", "prime_length"]; }
            else {
                if (_mode isEqualTo "key") then {
                    _lines pushBack "Possible key lengths:";
                    { _lines pushBack str _x; } forEach _keyLengths;
                };
                if (_mode isEqualTo "bruteforce") then {
                    {
                        private _col = _x; private _rows = _msgLen / _col;
                        _lines pushBack format ["cols=%1 rows=%2", _col, _rows];
                        private _arr = _text splitString "";
                        private _segments = []; private _indx = 0;
                        for "_i" from 1 to _col do { _segments pushBack (_arr select [_indx, _rows]); _indx = _indx + _rows; };
                        for "_i" from 0 to (_rows - 1) do {
                            private _colString = "";
                            for "_j" from 0 to (_col - 1) do { _colString = _colString + format ["%1 ", _segments select _j select _i]; };
                            _lines pushBack _colString;
                        };
                        _lines pushBack "";
                    } forEach _keyLengths;
                };
            };
        };
    };
    default { _res set ["error", "bad_algo"]; };
};

_res set ["lines", _lines];
_res

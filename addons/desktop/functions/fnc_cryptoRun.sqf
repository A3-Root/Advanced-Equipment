#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Web-desktop backend for the Cryptography > Crypto app. Encrypts or decrypts text with
 * the same caesar/columnar ciphers as the CLI `crypto` command (AE3_armaos_fnc_encryption_*), but
 * returns the result to the browser instead of writing to a terminal, so the GUI tool produces output
 * identical to the shell (#9). Pure computation - safe to run client-side.
 *
 * Arguments:
 * 0: _data <HASHMAP> - {mode:"encrypt"|"decrypt", algorithm:"caesar"|"columnar", key:STRING, text:STRING}
 *
 * Return Value:
 * Result <HASHMAP> - {error:STRING, result:STRING}
 *
 * Public: No
 */

params [["_data", createHashMap, [createHashMap]]];

private _mode = _data getOrDefault ["mode", "encrypt"];
private _algo = _data getOrDefault ["algorithm", "caesar"];
private _key  = _data getOrDefault ["key", ""];
private _text = _data getOrDefault ["text", ""];

private _res = createHashMapFromArray [["error", ""], ["result", ""]];

if (_text isEqualTo "") exitWith { _res set ["error", "no_input"]; _res };
if !(_mode in ["encrypt", "decrypt"]) exitWith { _res set ["error", "bad_mode"]; _res };

switch (_algo) do {
    case "caesar": {
        private _k = floor (parseNumber _key);
        if (_k <= 0) then { _res set ["error", "bad_key"]; }
        else { _res set ["result", [_k, _mode, _text] call AE3_armaos_fnc_encryption_caesar]; };
    };
    case "columnar": {
        if (count _key < 2) then { _res set ["error", "bad_key"]; }
        else {
            private _out = [_key, _mode, _text regexReplace [" ", "_"]] call AE3_armaos_fnc_encryption_columnar;
            if (_out isEqualTo "") then { _res set ["error", "len_mismatch"]; }
            else { _res set ["result", _out]; };
        };
    };
    default { _res set ["error", "bad_algo"]; };
};

_res

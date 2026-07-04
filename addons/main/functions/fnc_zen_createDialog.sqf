#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Guarded wrapper around Zeus Enhanced's Dynamic Dialog builder (zen_dialog_fnc_create).
 * Centralises the single call site so every AE3 ZEN dialog shares one runtime guard. ZEN is optional
 * and never a required addon, so the function is only ever dereferenced when it actually exists.
 *
 * Arguments:
 * 0: _title <STRING> - Dialog title (auto-localized/uppercased by ZEN)
 * 1: _rows <ARRAY> - ZEN content row specs
 * 2: _onConfirm <CODE> - Called with [values, args] on confirm
 * 3: _onCancel <CODE> - Called with [values, args] on cancel/ESC (default: {})
 * 4: _args <ANY> - Passed as second argument to the callbacks (default: [])
 * 5: _saveID <STRING> - Value-persistence key (default: "")
 *
 * Return Value:
 * Whether the dialog was created <BOOL>
 *
 * Example:
 * ["Title", [["EDIT", "Name", ""]], {systemChat str _this}] call AE3_main_fnc_zen_createDialog;
 *
 * Public: No
 */

params ["_title", "_rows", "_onConfirm", ["_onCancel", {}], ["_args", []], ["_saveID", ""]];

// zen_dialog_fnc_create is a runtime SQF symbol supplied by ZEN; absent when ZEN is not loaded.
if (isNil "zen_dialog_fnc_create") exitWith { false };

[_title, _rows, _onConfirm, _onCancel, _args, _saveID] call zen_dialog_fnc_create

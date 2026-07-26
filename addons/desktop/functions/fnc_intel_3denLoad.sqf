// File: fnc_intel_3denLoad.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: attributeLoad handler for the Add Intel 3DEN attribute control. Populates the combos,
 * applies the stored value to every child control (type, the per-type fields, owner/received-time,
 * the email address-creation checkboxes and the lockedfile permission grid) and then lays the fields
 * out for the selected type. The stored value is the flat array produced by fnc_intel_3denSave.
 *
 * Arguments:
 * 0: _group <CONTROL> - The 3DEN attribute controls group
 * 1: _value <STRING|ARRAY> - Stored attribute value (serialized string or already an array)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_this, _value] call AE3_desktop_fnc_intel_3denLoad;
 *
 * Public: No
 */

params ["_group", ["_value", []]];

// The attribute stores a serialized string; an empty value falls back to the type defaults.
if (_value isEqualType "") then
{
	_value = if (_value isEqualTo "") then { [] } else { parseSimpleArray _value };
};

_value params [
	["_type", "email"], ["_f1", ""], ["_f2", ""], ["_f3", ""], ["_f4", ""], ["_field5", "root"],
	["_createFrom", false], ["_createTo", false],
	["_oR", true], ["_oW", true], ["_oX", false], ["_eR", true], ["_eW", false], ["_eX", false]
];

[_group] call AE3_desktop_fnc_intel_initFields;

// Select the stored type in the combo.
private _combo = _group controlsGroupCtrl 1702;
for "_i" from 0 to (lbSize _combo) - 1 do
{
	if ((_combo lbData _i) isEqualTo _type) exitWith { _combo lbSetCurSel _i; };
};

(_group controlsGroupCtrl 1401) ctrlSetText _f1;
if (_type isEqualTo "media") then
{
	private _mediaCombo = _group controlsGroupCtrl 1602;
	for "_i" from 0 to (lbSize _mediaCombo) - 1 do
	{
		if ((_mediaCombo lbData _i) isEqualTo _f2) exitWith { _mediaCombo lbSetCurSel _i; };
	};
}
else
{
	(_group controlsGroupCtrl 1402) ctrlSetText _f2;
};
(_group controlsGroupCtrl 1403) ctrlSetText _f3;
(_group controlsGroupCtrl 1404) ctrlSetText _f4;
(_group controlsGroupCtrl 1405) ctrlSetText _field5;

(_group controlsGroupCtrl 1317) cbSetChecked _createFrom;
(_group controlsGroupCtrl 1318) cbSetChecked _createTo;
(_group controlsGroupCtrl 1301) cbSetChecked _oR;
(_group controlsGroupCtrl 1302) cbSetChecked _oW;
(_group controlsGroupCtrl 1303) cbSetChecked _oX;
(_group controlsGroupCtrl 1304) cbSetChecked _eR;
(_group controlsGroupCtrl 1305) cbSetChecked _eW;
(_group controlsGroupCtrl 1306) cbSetChecked _eX;

// React to later type changes and apply the initial layout.
_combo ctrlAddEventHandler ["LBSelChanged", {
	params ["_combo"];
	[ctrlParentControlsGroup _combo] call AE3_desktop_fnc_intel_updateFields;
}];
[_group] call AE3_desktop_fnc_intel_updateFields;

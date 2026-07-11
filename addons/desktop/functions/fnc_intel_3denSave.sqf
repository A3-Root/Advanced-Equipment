// File: fnc_intel_3denSave.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: attributeSave handler for the Add Intel 3DEN attribute control. Reads every child
 * control and returns a flat array describing the intel to plant. For the media type the second
 * field is taken from the kind dropdown rather than the text edit. The array is consumed by
 * fnc_module_addIntel and round-trips through fnc_intel_3denLoad.
 *
 * Arguments:
 * 0: _group <CONTROL> - The 3DEN attribute controls group
 *
 * Return Value:
 * Stored attribute value <STRING> - the serialized field array
 *
 * Example:
 * private _value = [_this] call AE3_desktop_fnc_intel_3denSave;
 *
 * Public: No
 */

params ["_group"];

private _combo = _group controlsGroupCtrl 1702;
private _type = _combo lbData (lbCurSel _combo);

private _f2 = if (_type isEqualTo "media") then
{
	private _mediaCombo = _group controlsGroupCtrl 1602;
	_mediaCombo lbData (lbCurSel _mediaCombo)
}
else
{
	ctrlText (_group controlsGroupCtrl 1402)
};

// Serialized to a string so it round-trips through the module attribute's STRING value.
str [
	_type,
	ctrlText (_group controlsGroupCtrl 1401),
	_f2,
	ctrlText (_group controlsGroupCtrl 1403),
	ctrlText (_group controlsGroupCtrl 1404),
	ctrlText (_group controlsGroupCtrl 1405),
	cbChecked (_group controlsGroupCtrl 1317),
	cbChecked (_group controlsGroupCtrl 1318),
	cbChecked (_group controlsGroupCtrl 1301),
	cbChecked (_group controlsGroupCtrl 1302),
	cbChecked (_group controlsGroupCtrl 1303),
	cbChecked (_group controlsGroupCtrl 1304),
	cbChecked (_group controlsGroupCtrl 1305),
	cbChecked (_group controlsGroupCtrl 1306)
]

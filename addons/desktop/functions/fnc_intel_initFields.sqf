// File: fnc_intel_initFields.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Populates the intel type combo (IDC 1702) and the media-kind combo (IDC 1602) of an
 * Add Intel UI container, which may be a dialog display (Zeus curator dialog) or a controls group
 * (3DEN attribute control). Each list entry stores its config id as item data. Existing entries are
 * cleared first so the call is idempotent. Shared by the Zeus dialog and the 3DEN module attribute.
 *
 * Arguments:
 * 0: _container <DISPLAY|CONTROL> - The intel dialog display or the 3DEN attribute controls group
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_desktop_fnc_intel_initFields;
 *
 * Public: No
 */

params ["_container"];

private _getCtrl = if (_container isEqualType controlNull) then
{
	{ _container controlsGroupCtrl _this }
}
else
{
	{ _container displayCtrl _this }
};

private _combo = 1702 call _getCtrl;
lbClear _combo;
{
	_x params ["_typeId", "_label"];
	private _index = _combo lbAdd _label;
	_combo lbSetData [_index, _typeId];
} forEach [
	["email", localize "STR_AE3_Desktop_Intel_Email"],
	["webpage", localize "STR_AE3_Desktop_Intel_Webpage"],
	["history", localize "STR_AE3_Desktop_Intel_History"],
	["media", localize "STR_AE3_Desktop_Intel_Media"],
	["lockedfile", localize "STR_AE3_Desktop_Intel_LockedFile"]
];
_combo lbSetCurSel 0;

private _mediaCombo = 1602 call _getCtrl;
lbClear _mediaCombo;
{
	_x params ["_mediaId", "_mediaLabel"];
	private _mi = _mediaCombo lbAdd _mediaLabel;
	_mediaCombo lbSetData [_mi, _mediaId];
} forEach [
	["image", localize "STR_AE3_Desktop_Intel_MediaImage"],
	["video", localize "STR_AE3_Desktop_Intel_MediaVideo"],
	["audio", localize "STR_AE3_Desktop_Intel_MediaAudio"]
];
_mediaCombo lbSetCurSel 0;

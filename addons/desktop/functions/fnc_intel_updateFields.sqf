#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Applies the per-type field layout for the Add Intel UI to a container, which may be a
 * dialog display (Zeus curator dialog) or a controls group (3DEN attribute control). The intel type
 * is read from the type combo (IDC 1702) and the labels, the media-kind picker, the email-only rows
 * and the lockedfile permission grid are shown, hidden and repositioned to match. Reused so the Zeus
 * dialog and the 3DEN module attribute behave identically.
 *
 * Arguments:
 * 0: _container <DISPLAY|CONTROL> - The intel dialog display or the 3DEN attribute controls group
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call AE3_desktop_fnc_intel_updateFields;
 *
 * Public: No
 */

params ["_container"];

// Resolve child controls from either a controls group (3DEN attribute) or a dialog display (Zeus).
private _getCtrl = if (_container isEqualType controlNull) then
{
	{ _container controlsGroupCtrl _this }
}
else
{
	{ _container displayCtrl _this }
};

private _combo = 1702 call _getCtrl;
private _type = _combo lbData (lbCurSel _combo);

private _labels = switch (_type) do
{
	case "webpage":    { [localize "STR_AE3_Desktop_Intel_LabelUrl", localize "STR_AE3_Desktop_Intel_LabelTitle", localize "STR_AE3_Desktop_Intel_LabelContent"] };
	case "history":    { [localize "STR_AE3_Desktop_Intel_LabelUrl", localize "STR_AE3_Desktop_Intel_LabelTime", ""] };
	case "media":      { [localize "STR_AE3_Desktop_Intel_LabelSource", localize "STR_AE3_Desktop_Intel_LabelMediaType", localize "STR_AE3_Desktop_Intel_LabelDest"] };
	case "lockedfile": { [localize "STR_AE3_Desktop_Intel_LabelDest", localize "STR_AE3_Desktop_Intel_LabelPassword", localize "STR_AE3_Desktop_Intel_LabelContent"] };
	default            { [localize "STR_AE3_Desktop_Intel_LabelFrom", localize "STR_AE3_Desktop_Intel_LabelTo", localize "STR_AE3_Desktop_Intel_LabelSubject"] };
};
(1710 call _getCtrl) ctrlSetText (_labels select 0);
(1711 call _getCtrl) ctrlSetText (_labels select 1);
(1712 call _getCtrl) ctrlSetText (_labels select 2);

private _isEmail = _type isEqualTo "email";
private _isLocked = _type isEqualTo "lockedfile";
// Media uses the kind dropdown (1602) in place of the second text field (1402).
private _isMedia = _type isEqualTo "media";
(1602 call _getCtrl) ctrlShow _isMedia;
(1402 call _getCtrl) ctrlShow (!_isMedia);
(1713 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelBody");
// email-only: body field
{
	(_x call _getCtrl) ctrlShow _isEmail;
} forEach [1713, 1404];
// shared: received-time row (email) / owner-name row (lockedfile)
{
	(_x call _getCtrl) ctrlShow (_isEmail || _isLocked);
} forEach [1714, 1405];
// email-only: sender/recipient address creation checkboxes and labels
{
	(_x call _getCtrl) ctrlShow _isEmail;
} forEach [1717, 1317, 1718, 1318];
{
	(_x call _getCtrl) ctrlEnable _isEmail;
} forEach [1317, 1318];
// lockedfile-only: permission column headers and all six permission checkboxes
{
	(_x call _getCtrl) ctrlShow _isLocked;
} forEach [1715, 1716, 1301, 1302, 1303, 1304, 1305, 1306];
if (_isEmail) then
{
	(1714 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelReceivedTime");
	(1717 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelCreateFromHandle");
	(1718 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelCreateToHandle");
	(1405 call _getCtrl) ctrlSetText "";
	(1317 call _getCtrl) cbSetChecked false;
	(1318 call _getCtrl) cbSetChecked false;
	// Derive one grid-row height from the y gap between body label (IDC 1713, y=11.2) and body field
	// (IDC 1404, y=12.2) so the received-time row can be placed without the all-caps grid macros.
	private _pLabel = ctrlPosition (1713 call _getCtrl);
	private _pBody  = ctrlPosition (1404 call _getCtrl);
	private _gH = (_pBody select 1) - (_pLabel select 1); // 1 grid row
	// Shrink body to h=2 rows so the received-time row fits directly below before the checkboxes.
	(1404 call _getCtrl) ctrlSetPosition [_pBody select 0, _pBody select 1, _pBody select 2, 2 * _gH];
	(1404 call _getCtrl) ctrlCommit 0;
	private _rowY = (_pBody select 1) + (2.3 * _gH);
	private _p14 = ctrlPosition (1714 call _getCtrl);
	private _p15 = ctrlPosition (1405 call _getCtrl);
	(1714 call _getCtrl) ctrlSetPosition [_p14 select 0, _rowY, _p14 select 2, _p14 select 3];
	(1405 call _getCtrl) ctrlSetPosition [_p15 select 0, _rowY, _p15 select 2, _p15 select 3];
	(1714 call _getCtrl) ctrlCommit 0;
	(1405 call _getCtrl) ctrlCommit 0;
};
if (_isLocked) then
{
	(1714 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelOwner");
	(1715 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelOwner");
	(1716 call _getCtrl) ctrlSetText (localize "STR_AE3_Desktop_Intel_LabelEveryone");
	// Restore the owner row to its config-defined position (body_y + 1 grid row).
	private _pLabel = ctrlPosition (1713 call _getCtrl);
	private _pBody  = ctrlPosition (1404 call _getCtrl);
	private _gH = (_pBody select 1) - (_pLabel select 1);
	private _origY = (_pBody select 1) + _gH;
	private _p14 = ctrlPosition (1714 call _getCtrl);
	private _p15 = ctrlPosition (1405 call _getCtrl);
	(1714 call _getCtrl) ctrlSetPosition [_p14 select 0, _origY, _p14 select 2, _p14 select 3];
	(1405 call _getCtrl) ctrlSetPosition [_p15 select 0, _origY, _p15 select 2, _p15 select 3];
	(1714 call _getCtrl) ctrlCommit 0;
	(1405 call _getCtrl) ctrlCommit 0;
};

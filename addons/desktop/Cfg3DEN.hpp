// Custom 3DEN attribute control for the AE3_AddIntel module. A single controls group hosts the intel
// type dropdown plus every per-type field; the visible fields follow the selected type (see
// fnc_intel_updateFields). attributeLoad/attributeSave round-trip a single flat value array, so the
// module reads one property (AE3_ModuleIntel_Data) instead of a static list of attributes.

class RscControlsGroupNoScrollbars;

class Cfg3DEN
{
	class Attributes
	{
		class AE3_Intel3denControl: RscControlsGroupNoScrollbars
		{
			idc = -1;
			attributeLoad = "[_this, _value] call AE3_desktop_fnc_intel_3denLoad;";
			attributeSave = "[_this] call AE3_desktop_fnc_intel_3denSave;";
			x = 0;
			y = 0;
			w = 40 * GUI_GRID_W;
			h = 21 * GUI_GRID_H;

			class Controls
			{
				class RscText_1701: RscText
				{
					idc = 1701;
					text = "$STR_AE3_Desktop_Config_IntelTypeDisplayName";
					x = 0 * GUI_GRID_W;
					y = 0 * GUI_GRID_H;
					w = 9 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};
				class RscCombo_1702: RscCombo
				{
					idc = 1702;
					x = 10 * GUI_GRID_W;
					y = 0 * GUI_GRID_H;
					w = 29 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};

				class RscText_1710: RscText
				{
					idc = 1710;
					text = "";
					x = 0 * GUI_GRID_W;
					y = 1.5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_MULTI;
					lineSpacing = 1;
				};
				class RscEdit_1401: RscEdit
				{
					idc = 1401;
					x = 0 * GUI_GRID_W;
					y = 2.5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};

				class RscText_1711: RscText
				{
					idc = 1711;
					text = "";
					x = 0 * GUI_GRID_W;
					y = 4 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_MULTI;
					lineSpacing = 1;
				};
				class RscEdit_1402: RscEdit
				{
					idc = 1402;
					x = 0 * GUI_GRID_W;
					y = 5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};
				// Media-type picker: replaces the second field for the "media" type. Hidden by default.
				class RscCombo_1602: RscCombo
				{
					idc = 1602;
					x = 0 * GUI_GRID_W;
					y = 5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};

				class RscText_1712: RscText
				{
					idc = 1712;
					text = "";
					x = 0 * GUI_GRID_W;
					y = 6.5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_MULTI;
					lineSpacing = 1;
				};
				class RscEdit_1403: RscEdit
				{
					idc = 1403;
					x = 0 * GUI_GRID_W;
					y = 7.5 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};

				class RscText_1713: RscText
				{
					idc = 1713;
					text = "";
					x = 0 * GUI_GRID_W;
					y = 8.7 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_MULTI;
					lineSpacing = 1;
				};
				class RscEdit_1404: RscEdit
				{
					idc = 1404;
					x = 0 * GUI_GRID_W;
					y = 9.7 * GUI_GRID_H;
					w = 39 * GUI_GRID_W;
					h = 3 * GUI_GRID_H;
					style = ST_MULTI;
					lineSpacing = 1;
				};

				class RscText_1714: RscText
				{
					idc = 1714;
					text = "$STR_AE3_Desktop_Intel_LabelOwner";
					x = 0 * GUI_GRID_W;
					y = 10.7 * GUI_GRID_H;
					w = 9 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};
				class RscEdit_1405: RscEdit
				{
					idc = 1405;
					text = "root";
					x = 10 * GUI_GRID_W;
					y = 10.7 * GUI_GRID_H;
					w = 29 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
				};

				class RscText_1715: RscText
				{
					idc = 1715;
					text = "$STR_AE3_Desktop_Intel_LabelOwner";
					x = 10 * GUI_GRID_W;
					y = 12.2 * GUI_GRID_H;
					w = 8 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_CENTER;
				};
				class RscText_1716: RscText
				{
					idc = 1716;
					text = "$STR_AE3_Desktop_Intel_LabelEveryone";
					x = 22 * GUI_GRID_W;
					y = 12.2 * GUI_GRID_H;
					w = 8 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					style = ST_CENTER;
				};
				// Email-only: sender address creation checkbox + label (hidden by default).
				class RscCheckBox_1317: RscCheckBox
				{
					idc = 1317;
					x = 10 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 0;
					onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
				};
				class RscText_1717: RscText
				{
					idc = 1717;
					text = "";
					x = 11.2 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 26 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				// Email-only: recipient address creation checkbox + label (hidden by default).
				class RscCheckBox_1318: RscCheckBox
				{
					idc = 1318;
					x = 10 * GUI_GRID_W;
					y = 15 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 0;
					onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
				};
				class RscText_1718: RscText
				{
					idc = 1718;
					text = "";
					x = 11.2 * GUI_GRID_W;
					y = 15 * GUI_GRID_H;
					w = 26 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				// Lockedfile-only: owner permission checkboxes (r/w/x), hidden by default.
				class RscCheckBox_1301: RscCheckBox
				{
					idc = 1301;
					x = 10 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 1;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				class RscCheckBox_1302: RscCheckBox
				{
					idc = 1302;
					x = 13 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 1;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				class RscCheckBox_1303: RscCheckBox
				{
					idc = 1303;
					x = 16 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 0;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				class RscCheckBox_1304: RscCheckBox
				{
					idc = 1304;
					x = 22 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 1;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				class RscCheckBox_1305: RscCheckBox
				{
					idc = 1305;
					x = 25 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 0;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
				class RscCheckBox_1306: RscCheckBox
				{
					idc = 1306;
					x = 28 * GUI_GRID_W;
					y = 13.5 * GUI_GRID_H;
					w = 1 * GUI_GRID_W;
					h = 1 * GUI_GRID_H;
					checked = 0;
					onLoad = "params ['_control']; _control ctrlShow false;";
				};
			};
		};
	};
};

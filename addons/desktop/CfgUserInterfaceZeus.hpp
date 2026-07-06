// RscText and RscButton are already declared in ui\RscAE3Desktop.hpp (included earlier in config.cpp)
class RscEdit;
class RscCombo;
class RscListBox;
class RscCheckBox;
class RscButtonMenuOK;
class RscButtonMenuCancel;

// Zeus dialog for the AE3_AddIntel module: type selector + three fields whose meaning
// depends on the type (see fnc_zeus_module_addIntel for the per-type labels)
class AE3_UserInterface_Zeus_Module_AddIntel
{
	idd = 17100;
	movingEnable = 1;
	enableSimulation = 1;

	onLoad = "params ['_display']; [_display, 0, 'onLoad'] call AE3_desktop_fnc_zeus_module_addIntel;";
	onUnload = "params ['_display', '_exitCode']; [_display, _exitCode, 'onUnload'] call AE3_desktop_fnc_zeus_module_addIntel;";

	class controlsBackground
	{
		class RscText_900: RscText
		{
			idc = 900;
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 2 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 23.5 * GUI_GRID_H;
			colorBackground[] = {0.2,0.2,0.2,1};
		};
	};

	class controls
	{
		class RscText_1000: RscText
		{
			idc = 1000;
			text = "$STR_AE3_Desktop_Config_AddIntelDisplayName";
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 0 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 1.5 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,1};
		};

		class RscText_1701: RscText
		{
			idc = 1701;
			text = "$STR_AE3_Desktop_Config_IntelTypeDisplayName";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1702: RscCombo
		{
			idc = 1702;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		// Labels sit full-width above their field so long per-type hint text never clips.
		class RscText_1710: RscText
		{
			idc = 1710;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 4 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
		};
		class RscEdit_1401: RscEdit
		{
			idc = 1401;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 5 * GUI_GRID_H + GUI_GRID_Y;
			w = 32.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		// Opens the filesystem browser as a path picker for the linked laptop; shown only for the
		// filesystem-path types (media source / locked-file destination) by AE3_desktop_fnc_intel_updateFields.
		class RscButton_1720: RscButton
		{
			idc = 1720;
			text = "$STR_AE3_Desktop_Intel_Browse";
			x = 33.5 * GUI_GRID_W + GUI_GRID_X;
			y = 5 * GUI_GRID_H + GUI_GRID_Y;
			w = 6 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			onButtonClick = "[ctrlParent (_this select 0)] call AE3_desktop_fnc_intel_browsePath;";
		};

		class RscText_1711: RscText
		{
			idc = 1711;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 6.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
		};
		class RscEdit_1402: RscEdit
		{
			idc = 1402;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 7.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		// Media-type picker: replaces the second field for the "media" type so the kind is chosen
		// from a list instead of typed. Hidden by default; shown (with edit 1402 hidden) for media.
		class RscCombo_1602: RscCombo
		{
			idc = 1602;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 7.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			onLoad = "params ['_control']; _control ctrlShow false;";
		};

		class RscText_1712: RscText
		{
			idc = 1712;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 9 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
		};
		// Subject is a single line; the body below is the multi-line field.
		class RscEdit_1403: RscEdit
		{
			idc = 1403;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscText_1713: RscText
		{
			idc = 1713;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
		};
		class RscEdit_1404: RscEdit
		{
			idc = 1404;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 12.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 3 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
		};

		class RscText_1714: RscText
		{
			idc = 1714;
			text = "$STR_AE3_Desktop_Intel_LabelOwner";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 13.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscEdit_1405: RscEdit
		{
			idc = 1405;
			text = "root";
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 13.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscText_1715: RscText
		{
			idc = 1715;
			text = "$STR_AE3_Desktop_Intel_LabelOwner";
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 14.7 * GUI_GRID_H + GUI_GRID_Y;
			w = 8 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_CENTER;
		};
		class RscText_1716: RscText
		{
			idc = 1716;
			text = "$STR_AE3_Desktop_Intel_LabelEveryone";
			x = 22 * GUI_GRID_W + GUI_GRID_X;
			y = 14.7 * GUI_GRID_H + GUI_GRID_Y;
			w = 8 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_CENTER;
		};
		// Email-only: sender address creation checkbox + label (hidden by default, shown for email type)
		class RscCheckBox_1317: RscCheckBox
		{
			idc = 1317;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 0;
			onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
		};
		class RscText_1717: RscText
		{
			idc = 1717;
			text = "";
			x = 11.2 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 26 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			onLoad = "params ['_control']; _control ctrlShow false;";
		};
		// Email-only: recipient address creation checkbox + label (hidden by default, shown for email type)
		class RscCheckBox_1318: RscCheckBox
		{
			idc = 1318;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 17.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 0;
			onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
		};
		class RscText_1718: RscText
		{
			idc = 1718;
			text = "";
			x = 11.2 * GUI_GRID_W + GUI_GRID_X;
			y = 17.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 26 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			onLoad = "params ['_control']; _control ctrlShow false;";
		};
		// Lockedfile-only: owner permission checkboxes (r/w/x)
		class RscCheckBox_1301: RscCheckBox
		{
			idc = 1301;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 1;
			onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
		};
		class RscCheckBox_1302: RscCheckBox
		{
			idc = 1302;
			x = 13 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 1;
			onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
		};
		class RscCheckBox_1303: RscCheckBox
		{
			idc = 1303;
			x = 16 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 0;
		};
		class RscCheckBox_1304: RscCheckBox
		{
			idc = 1304;
			x = 22 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 1;
		};
		class RscCheckBox_1305: RscCheckBox
		{
			idc = 1305;
			x = 25 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 0;
		};
		class RscCheckBox_1306: RscCheckBox
		{
			idc = 1306;
			x = 28 * GUI_GRID_W + GUI_GRID_X;
			y = 16 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			checked = 0;
		};

		class RscText_1720: RscText
		{
			idc = 1720;
			text = "$STR_AE3_Desktop_Config_IntelTargetHint";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 19.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
			colorText[] = {0.7,0.7,0.7,1};
		};

		// Media-only: pasting raw base64 image data here stores it as an inline picture (rendered by
		// the in-OS web viewer) instead of registering a real texture path. Repositioned and shown for
		// the media type by AE3_desktop_fnc_intel_updateFields; hidden by default.
		class RscText_1721: RscText
		{
			idc = 1721;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 12.4 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
			onLoad = "params ['_control']; _control ctrlShow false;";
		};
		class RscEdit_1420: RscEdit
		{
			idc = 1420;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 13.4 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 2.4 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
			onLoad = "params ['_control']; _control ctrlShow false; _control ctrlEnable false;";
		};

		class RscButtonMenuOK_1600: RscButtonMenuOK
		{
			idc = 1; // IDC_OK: engine auto-closes the dialog with exit code 1 (do not change)
			x = 30 * GUI_GRID_W + GUI_GRID_X;
			y = 22.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButtonMenuCancel_1601: RscButtonMenuCancel
		{
			idc = 2; // IDC_CANCEL: engine auto-closes the dialog with exit code 2 (do not change)
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 22.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
	};
};

// Zeus dialog for the AE3_InterfaceAccess module: interface-mode combo, a per-player
// CLI/GUI/Both/None list and a per-side fallback for players not in the list (e.g. JIP).
// See fnc_zeus_module_interfaceAccess for the logic.
class AE3_UserInterface_Zeus_Module_InterfaceAccess
{
	idd = 17110;
	movingEnable = 1;
	enableSimulation = 1;

	onLoad = "params ['_display']; [_display, 0, 'onLoad'] call AE3_desktop_fnc_zeus_module_interfaceAccess;";
	onUnload = "params ['_display', '_exitCode']; [_display, _exitCode, 'onUnload'] call AE3_desktop_fnc_zeus_module_interfaceAccess;";

	class controlsBackground
	{
		class RscText_900: RscText
		{
			idc = 900;
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 2 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 18 * GUI_GRID_H;
			colorBackground[] = {0.2,0.2,0.2,1};
		};
	};

	class controls
	{
		class RscText_1000: RscText
		{
			idc = 1000;
			text = "$STR_AE3_Desktop_Config_InterfaceAccessDisplayName";
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 0 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 1.5 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,1};
		};

		// Interface mode
		class RscText_1731: RscText
		{
			idc = 1731;
			text = "$STR_AE3_Desktop_Access_Mode";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1730: RscCombo
		{
			idc = 1730;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		// Per-player list
		class RscText_1739: RscText
		{
			idc = 1739;
			text = "$STR_AE3_Desktop_Access_Players";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 4 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscListBox_1740: RscListBox
		{
			idc = 1740;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 5 * GUI_GRID_H;
		};

		// Access buttons applied to the selected player
		class RscButton_1741: RscButton
		{
			idc = 1741;
			text = "$STR_AE3_Desktop_Access_CLI";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButton_1742: RscButton
		{
			idc = 1742;
			text = "$STR_AE3_Desktop_Access_GUI";
			x = 10.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButton_1743: RscButton
		{
			idc = 1743;
			text = "$STR_AE3_Desktop_Access_Both";
			x = 20.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButton_1744: RscButton
		{
			idc = 1744;
			text = "$STR_AE3_Desktop_Access_None";
			x = 30.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		// Per-side fallback (players not individually listed, incl. JIP)
		class RscText_1749: RscText
		{
			idc = 1749;
			text = "$STR_AE3_Desktop_Access_SideFallback";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 12 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscText_1751: RscText
		{
			idc = 1751;
			text = "$STR_AE3_Desktop_Access_SideWest";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 13 * GUI_GRID_H + GUI_GRID_Y;
			w = 6 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1750: RscCombo
		{
			idc = 1750;
			x = 7 * GUI_GRID_W + GUI_GRID_X;
			y = 13 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscText_1753: RscText
		{
			idc = 1753;
			text = "$STR_AE3_Desktop_Access_SideEast";
			x = 20 * GUI_GRID_W + GUI_GRID_X;
			y = 13 * GUI_GRID_H + GUI_GRID_Y;
			w = 6 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1752: RscCombo
		{
			idc = 1752;
			x = 27 * GUI_GRID_W + GUI_GRID_X;
			y = 13 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscText_1755: RscText
		{
			idc = 1755;
			text = "$STR_AE3_Desktop_Access_SideGuer";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 14 * GUI_GRID_H + GUI_GRID_Y;
			w = 6 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1754: RscCombo
		{
			idc = 1754;
			x = 7 * GUI_GRID_W + GUI_GRID_X;
			y = 14 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscText_1757: RscText
		{
			idc = 1757;
			text = "$STR_AE3_Desktop_Access_SideCiv";
			x = 20 * GUI_GRID_W + GUI_GRID_X;
			y = 14 * GUI_GRID_H + GUI_GRID_Y;
			w = 6 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscCombo_1756: RscCombo
		{
			idc = 1756;
			x = 27 * GUI_GRID_W + GUI_GRID_X;
			y = 14 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscText_1760: RscText
		{
			idc = 1760;
			text = "$STR_AE3_Desktop_Access_Hint";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 15.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
			colorText[] = {0.7,0.7,0.7,1};
		};

		class RscButtonMenuOK_1600: RscButtonMenuOK
		{
			idc = 1; // IDC_OK: engine auto-closes the dialog with exit code 1 (do not change)
			x = 30 * GUI_GRID_W + GUI_GRID_X;
			y = 18.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButtonMenuCancel_1601: RscButtonMenuCancel
		{
			idc = 2; // IDC_CANCEL: engine auto-closes the dialog with exit code 2 (do not change)
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 18.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
	};
};

// RscText is already declared in ui\RscAE3Desktop.hpp (included earlier in config.cpp)
class RscEdit;
class RscCombo;
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
			h = 14 * GUI_GRID_H;
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

		class RscText_1710: RscText
		{
			idc = 1710;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 4.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscEdit_1401: RscEdit
		{
			idc = 1401;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 4.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscText_1711: RscText
		{
			idc = 1711;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 6 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscEdit_1402: RscEdit
		{
			idc = 1402;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 6 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscText_1712: RscText
		{
			idc = 1712;
			text = "";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 7.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscEdit_1403: RscEdit
		{
			idc = 1403;
			x = 10 * GUI_GRID_W + GUI_GRID_X;
			y = 7.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 29 * GUI_GRID_W;
			h = 3 * GUI_GRID_H;
		};

		class RscText_1720: RscText
		{
			idc = 1720;
			text = "$STR_AE3_Desktop_Config_IntelTargetHint";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			style = ST_MULTI;
			lineSpacing = 1;
			colorText[] = {0.7,0.7,0.7,1};
		};

		class RscButtonMenuOK_1600: RscButtonMenuOK
		{
			idc = 1600;
			x = 30 * GUI_GRID_W + GUI_GRID_X;
			y = 14.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButtonMenuCancel_1601: RscButtonMenuCancel
		{
			idc = 1601;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 14.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
	};
};

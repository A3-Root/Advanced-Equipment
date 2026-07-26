/* ================================================================================ */

// RscText and RscEdit are already forward-declared in dialog.hpp (included earlier in config.cpp).
class RscCombo;
class RscButtonMenuOK;
class RscButtonMenuCancel;

/* ================================================================================ */

// Built-in Zeus dialog for the AE3_SaveLaptop module: a single save-slot name field. Used as the
// fallback when Zeus Enhanced is not loaded (opened by AE3_armaos_fnc_zeus_module_saveLaptop). The
// slot is handed back to the server via AE3_armaos_fnc_module_saveLaptopApply. The module + laptop
// netIds are stashed in uiNamespace by the opener and consumed here.
class AE3_UserInterface_Zeus_Module_SaveLaptop
{
	idd = 17130;
	movingEnable = 1;
	enableSimulation = 1;

	onUnload = "params ['_display', '_exitCode']; private _args = uiNamespace getVariable ['AE3_armaos_saveLaptopArgs', []]; if (_args isEqualTo []) exitWith {}; uiNamespace setVariable ['AE3_armaos_saveLaptopArgs', []]; _args params ['_m', '_u']; if (_exitCode == 2) exitWith { (objectFromNetId _m) remoteExec ['deleteVehicle', 2]; }; private _slot = ctrlText (_display displayCtrl 1401); [_m, _u, _slot] remoteExec ['AE3_armaos_fnc_module_saveLaptopApply', 2];";

	class controlsBackground
	{
		class RscText_900: RscText
		{
			idc = 900;
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 2 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 11 * GUI_GRID_H;
			colorBackground[] = {0.2,0.2,0.2,1};
		};
	};

	class controls
	{
		class RscText_1000: RscText
		{
			idc = 1000;
			text = "$STR_AE3_ArmaOS_Config_SaveLaptopDisplayName";
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 0 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 1.5 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,1};
		};

		class RscText_1400: RscText
		{
			idc = 1400;
			text = "$STR_AE3_ArmaOS_Config_ModuleSaveLaptopDescription";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 4 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,0.5};
			style = ST_MULTI;
			lineSpacing = 1;
		};

		class RscText_1001: RscText
		{
			idc = 1001;
			text = "$STR_AE3_ArmaOS_Config_SaveSlotDisplayName";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 7 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_RIGHT;
		};
		class RscEdit_1401: RscEdit
		{
			idc = 1401;
			text = "slot1";
			x = 13 * GUI_GRID_W + GUI_GRID_X;
			y = 7 * GUI_GRID_H + GUI_GRID_Y;
			w = 26.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,0.5};
		};

		class RscButtonMenuOK_1600: RscButtonMenuOK
		{
			idc = 1; // IDC_OK: engine auto-closes the dialog with exit code 1 (do not change)
			x = 30 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButtonMenuCancel_1601: RscButtonMenuCancel
		{
			idc = 2; // IDC_CANCEL: engine auto-closes the dialog with exit code 2 (do not change)
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
	};
};

/* ================================================================================ */

// Built-in Zeus dialog for the AE3_RestoreLaptop module: a combo listing stored save slots. Used as
// the fallback when Zeus Enhanced is not loaded (opened by AE3_armaos_fnc_zeus_module_restoreLaptop,
// which also fills the combo from the server-provided slot list). The chosen slot is handed back to
// the server via AE3_armaos_fnc_module_restoreLaptopApply.
class AE3_UserInterface_Zeus_Module_RestoreLaptop
{
	idd = 17131;
	movingEnable = 1;
	enableSimulation = 1;

	onUnload = "params ['_display', '_exitCode']; private _args = uiNamespace getVariable ['AE3_armaos_restoreLaptopArgs', []]; if (_args isEqualTo []) exitWith {}; uiNamespace setVariable ['AE3_armaos_restoreLaptopArgs', []]; _args params ['_m', '_u']; if (_exitCode == 2) exitWith { (objectFromNetId _m) remoteExec ['deleteVehicle', 2]; }; private _combo = _display displayCtrl 1500; private _sel = lbCurSel _combo; if (_sel < 0) exitWith { (objectFromNetId _m) remoteExec ['deleteVehicle', 2]; }; private _slot = _combo lbData _sel; [_m, _u, _slot] remoteExec ['AE3_armaos_fnc_module_restoreLaptopApply', 2];";

	class controlsBackground
	{
		class RscText_900: RscText
		{
			idc = 900;
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 2 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 11 * GUI_GRID_H;
			colorBackground[] = {0.2,0.2,0.2,1};
		};
	};

	class controls
	{
		class RscText_1000: RscText
		{
			idc = 1000;
			text = "$STR_AE3_ArmaOS_Config_RestoreLaptopDisplayName";
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 0 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 1.5 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,1};
		};

		class RscText_1400: RscText
		{
			idc = 1400;
			text = "$STR_AE3_ArmaOS_Config_ModuleRestoreLaptopDescription";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 39 * GUI_GRID_W;
			h = 4 * GUI_GRID_H;
			colorBackground[] = {-1,-1,-1,0.5};
			style = ST_MULTI;
			lineSpacing = 1;
		};

		class RscText_1001: RscText
		{
			idc = 1001;
			text = "$STR_AE3_ArmaOS_Config_SaveSlotDisplayName";
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 7 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			style = ST_RIGHT;
		};
		class RscCombo_1500: RscCombo
		{
			idc = 1500;
			x = 13 * GUI_GRID_W + GUI_GRID_X;
			y = 7 * GUI_GRID_H + GUI_GRID_Y;
			w = 26.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

		class RscButtonMenuOK_1600: RscButtonMenuOK
		{
			idc = 1; // IDC_OK: engine auto-closes the dialog with exit code 1 (do not change)
			x = 30 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class RscButtonMenuCancel_1601: RscButtonMenuCancel
		{
			idc = 2; // IDC_CANCEL: engine auto-closes the dialog with exit code 2 (do not change)
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 9.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
	};
};

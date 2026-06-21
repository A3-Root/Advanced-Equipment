// Minimal Rsc base classes are referenced from the base game (external class references).
// RscButton is declared here (this file is included first) and reused by CfgUserInterfaceZeus.hpp.
class RscText;
class RscButton;
class RscMapControl;

// The AE3 desktop display. All windows, icons and the taskbar are created dynamically
// via ctrlCreate by the window manager (see fnc_desktop_open / fnc_wm_createWindow).
class AE3_Desktop_Display
{
	idd = 17000;
	movingEnable = 0;
	enableSimulation = 1;
	onUnload = "call AE3_desktop_fnc_desktop_onUnload";

	class controlsBackground
	{
		class AE3_Desktop_Wallpaper : RscText
		{
			idc = 17001;
			x = "safezoneX";
			y = "safezoneY";
			w = "safezoneW";
			h = "safezoneH";
			colorBackground[] = {0.08, 0.10, 0.12, 1};
		};

		class AE3_Desktop_Taskbar : RscText
		{
			idc = 17002;
			x = "safezoneX";
			y = "safezoneY + safezoneH - 0.04";
			w = "safezoneW";
			h = "0.04";
			colorBackground[] = {0.05, 0.05, 0.06, 0.95};
		};

		class AE3_Desktop_Clock : RscText
		{
			idc = 17003;
			x = "safezoneX + safezoneW - 0.12";
			y = "safezoneY + safezoneH - 0.04";
			w = "0.11";
			h = "0.04";
			sizeEx = 0.03;
			text = "";
		};

		class AE3_Desktop_Hostname : RscText
		{
			idc = 17004;
			x = "safezoneX + 0.01";
			y = "safezoneY + safezoneH - 0.04";
			w = "0.4";
			h = "0.04";
			sizeEx = 0.03;
			text = "";
		};
	};

	class controls {};
};

// R1 spike: fullscreen CEF web-browser display for the HTML/JS desktop port (WS-B).
// A single control of type 106 (Arma's web browser control) fills the screen; the HTML/JS
// UI is loaded via ctrlWebBrowserAction ["LoadFile", ...] in AE3_desktop_fnc_desktop_openWeb.
// Mirrors os-master's RscWin99OSDisplayControl. Kept separate from AE3_Desktop_Display so the
// existing native desktop keeps working until the web port reaches feature parity.
class AE3_Desktop_BrowserDisplay
{
	idd = 17010;
	movingEnable = 0;
	enableSimulation = 1;
	fadein = 0;
	fadeout = 0;
	onUnload = "call AE3_desktop_fnc_desktop_webUnload";

	class controlsBackground
	{
		class AE3_Browser_Bg : RscText
		{
			idc = 17011;
			x = "safezoneX";
			y = "safezoneY";
			w = "safezoneW";
			h = "safezoneH";
			colorBackground[] = {0, 0, 0, 1};
		};
	};

	class controls
	{
		class AE3_Browser : RscText
		{
			type = 106; // CT_WEB_BROWSER (CEF)
			idc = 1337;
			x = "safezoneX";
			y = "safezoneY";
			w = "safezoneW";
			h = "safezoneH";
		};
	};
};

// Native real-world map overlay (#5). CEF cannot host Arma's map control, so the Map app opens this
// dialog layered over the web desktop showing the genuine RscMapControl centred on the laptop, with
// local markers for the player and nearby AE3 devices/routers. Created by AE3_desktop_fnc_mapOpen.
class AE3_Desktop_MapOverlay
{
	idd = 17020;
	movingEnable = 0;
	enableSimulation = 1;
	fadein = 0;
	fadeout = 0;
	// Clean up the local markers created for this overlay when it closes.
	onUnload = "{ deleteMarkerLocal _x } forEach (uiNamespace getVariable ['AE3_mapOverlayMarkers', []]); uiNamespace setVariable ['AE3_mapOverlayMarkers', []];";

	class controlsBackground
	{
		class AE3_MapBg : RscText
		{
			idc = -1;
			x = "safezoneX + 0.02";
			y = "safezoneY + 0.02";
			w = "safezoneW - 0.04";
			h = "safezoneH - 0.04";
			colorBackground[] = {0, 0, 0, 0.92};
		};
	};

	class controls
	{
		class AE3_MapTitle : RscText
		{
			idc = -1;
			x = "safezoneX + 0.03";
			y = "safezoneY + 0.03";
			w = "0.4";
			h = "0.04";
			sizeEx = 0.035;
			text = "Map";
		};

		// Pan instruction (#10): the RscMapControl only pans while RMB is held.
		class AE3_MapHint : RscText
		{
			idc = -1;
			x = "safezoneX + 0.28";
			y = "safezoneY + 0.03";
			w = "safezoneW - 0.44";
			h = "0.04";
			sizeEx = 0.03;
			colorText[] = {1, 0.85, 0.35, 1};
			text = "Hold Right Mouse Button to pan the map";
		};

		class AE3_MapClose : RscButton
		{
			idc = 17022;
			x = "safezoneX + safezoneW - 0.13";
			y = "safezoneY + 0.03";
			w = "0.1";
			h = "0.04";
			text = "Close";
			onButtonClick = "(ctrlParent (_this select 0)) closeDisplay 0;";
		};

		class AE3_Map : RscMapControl
		{
			idc = 17021;
			x = "safezoneX + 0.03";
			y = "safezoneY + 0.08";
			w = "safezoneW - 0.06";
			h = "safezoneH - 0.11";
		};
	};
};

// Minimal Rsc base classes are referenced from the base game (external class references)
class RscText;

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

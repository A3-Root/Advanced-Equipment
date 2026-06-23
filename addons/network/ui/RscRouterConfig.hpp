// Router configuration dialog: opened from the router's ACE interaction menu (the same menu
// as Connect/Disconnect). Lets the operator set the network name, wireless range and password in
// game, applied via AE3_network_fnc_applyRouterConfig.

class AE3_RouterConfigDialog
{
	idd = 17030;
	movingEnable = 0;
	enableSimulation = 1;

	class controlsBackground
	{
		class AE3_RC_Bg : RscText
		{
			idc = -1;
			x = "0.30 * safezoneW + safezoneX";
			y = "0.34 * safezoneH + safezoneY";
			w = "0.40 * safezoneW";
			h = "0.32 * safezoneH";
			colorBackground[] = {0.10, 0.10, 0.10, 0.95};
		};
	};

	class controls
	{
		class AE3_RC_Title : RscText
		{
			idc = -1;
			text = "Router Settings";
			x = "0.31 * safezoneW + safezoneX";
			y = "0.35 * safezoneH + safezoneY";
			w = "0.38 * safezoneW";
			h = "0.04 * safezoneH";
			sizeEx = 0.045;
			colorText[] = {0.91, 0.33, 0.13, 1};
		};

		class AE3_RC_LblName : RscText
		{
			idc = -1; text = "Network name";
			x = "0.31 * safezoneW + safezoneX"; y = "0.40 * safezoneH + safezoneY";
			w = "0.16 * safezoneW"; h = "0.035 * safezoneH";
		};
		class AE3_RC_Name : RscEdit
		{
			idc = 17031;
			x = "0.47 * safezoneW + safezoneX"; y = "0.40 * safezoneH + safezoneY";
			w = "0.21 * safezoneW"; h = "0.035 * safezoneH";
			colorBackground[] = {0, 0, 0, 0.5};
		};

		class AE3_RC_LblRange : RscText
		{
			idc = -1; text = "Wifi Range (m)";
			x = "0.31 * safezoneW + safezoneX"; y = "0.45 * safezoneH + safezoneY";
			w = "0.16 * safezoneW"; h = "0.035 * safezoneH";
		};
		class AE3_RC_Range : RscEdit
		{
			idc = 17032;
			x = "0.47 * safezoneW + safezoneX"; y = "0.45 * safezoneH + safezoneY";
			w = "0.21 * safezoneW"; h = "0.035 * safezoneH";
			colorBackground[] = {0, 0, 0, 0.5};
		};

		class AE3_RC_LblPass : RscText
		{
			idc = -1; text = "Password (blank = open)";
			x = "0.31 * safezoneW + safezoneX"; y = "0.50 * safezoneH + safezoneY";
			w = "0.16 * safezoneW"; h = "0.035 * safezoneH";
		};
		class AE3_RC_Pass : RscEdit
		{
			idc = 17033;
			x = "0.47 * safezoneW + safezoneX"; y = "0.50 * safezoneH + safezoneY";
			w = "0.21 * safezoneW"; h = "0.035 * safezoneH";
			colorBackground[] = {0, 0, 0, 0.5};
		};

		class AE3_RC_LblGateway : RscText
		{
			idc = -1; text = "Default gateway (a.b.c.d)";
			x = "0.31 * safezoneW + safezoneX"; y = "0.55 * safezoneH + safezoneY";
			w = "0.16 * safezoneW"; h = "0.035 * safezoneH";
		};
		class AE3_RC_Gateway : RscEdit
		{
			idc = 17034;
			x = "0.47 * safezoneW + safezoneX"; y = "0.55 * safezoneH + safezoneY";
			w = "0.21 * safezoneW"; h = "0.035 * safezoneH";
			colorBackground[] = {0, 0, 0, 0.5};
		};

		class AE3_RC_Apply : RscButton
		{
			idc = -1;
			text = "Apply";
			x = "0.47 * safezoneW + safezoneX"; y = "0.61 * safezoneH + safezoneY";
			w = "0.10 * safezoneW"; h = "0.04 * safezoneH";
			colorBackground[] = {0.91, 0.33, 0.13, 1};
			onButtonClick = "call AE3_network_fnc_router_applyConfigDialog;";
		};
		class AE3_RC_Cancel : RscButton
		{
			idc = -1;
			text = "Cancel";
			x = "0.58 * safezoneW + safezoneX"; y = "0.61 * safezoneH + safezoneY";
			w = "0.10 * safezoneW"; h = "0.04 * safezoneH";
			onButtonClick = "(ctrlParent (_this select 0)) closeDisplay 0;";
		};
	};
};

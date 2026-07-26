// Password prompt shown when joining a password-protected router from the ACE interaction menu.
// The entered password is checked against the router's AE3_network_password before the connection
// is made (AE3_network_fnc_connectSubmitPassword).

class AE3_NetworkPasswordDialog
{
	idd = 17040;
	movingEnable = 0;
	enableSimulation = 1;

	class controlsBackground
	{
		class AE3_NP_Bg : RscText
		{
			idc = -1;
			x = "0.35 * safezoneW + safezoneX";
			y = "0.42 * safezoneH + safezoneY";
			w = "0.30 * safezoneW";
			h = "0.16 * safezoneH";
			colorBackground[] = {0.10, 0.10, 0.10, 0.95};
		};
	};

	class controls
	{
		class AE3_NP_Title : RscText
		{
			idc = -1;
			text = "$STR_AE3_Network_Interaction_ConnectToRouter";
			x = "0.36 * safezoneW + safezoneX"; y = "0.43 * safezoneH + safezoneY";
			w = "0.28 * safezoneW"; h = "0.04 * safezoneH";
			sizeEx = 0.045;
			colorText[] = {0.91, 0.33, 0.13, 1};
		};

		class AE3_NP_Lbl : RscText
		{
			idc = -1;
			text = "$STR_AE3_Network_Interaction_EnterPassword";
			x = "0.36 * safezoneW + safezoneX"; y = "0.48 * safezoneH + safezoneY";
			w = "0.28 * safezoneW"; h = "0.035 * safezoneH";
		};

		class AE3_NP_Pass : RscEdit
		{
			idc = 17041;
			x = "0.36 * safezoneW + safezoneX"; y = "0.515 * safezoneH + safezoneY";
			w = "0.28 * safezoneW"; h = "0.035 * safezoneH";
			colorBackground[] = {0, 0, 0, 0.5};
		};

		class AE3_NP_Connect : RscButton
		{
			idc = -1;
			text = "$STR_AE3_Network_Interaction_ConnectToRouter";
			x = "0.36 * safezoneW + safezoneX"; y = "0.55 * safezoneH + safezoneY";
			w = "0.135 * safezoneW"; h = "0.04 * safezoneH";
			colorBackground[] = {0.91, 0.33, 0.13, 1};
			onButtonClick = "call AE3_network_fnc_connectSubmitPassword;";
		};
		class AE3_NP_Cancel : RscButton
		{
			idc = -1;
			text = "$STR_AE3_Network_Interaction_Cancel";
			x = "0.505 * safezoneW + safezoneX"; y = "0.55 * safezoneH + safezoneY";
			w = "0.135 * safezoneW"; h = "0.04 * safezoneH";
			onButtonClick = "(ctrlParent (_this select 0)) closeDisplay 0;";
		};
	};
};

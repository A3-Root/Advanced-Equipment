class Extended_PreInit_EventHandlers
{
	class ADDON
	{
        init = "call compile preprocessFileLineNumbers '\z\ae3\addons\desktop\XEH_preInit.sqf'";
        serverInit = "";
        clientInit = "";
	};
};

class Extended_PostInit_EventHandlers
{
	class ADDON
	{
        init = "call compile preprocessFileLineNumbers '\z\ae3\addons\desktop\XEH_postInit.sqf'";
	};
};

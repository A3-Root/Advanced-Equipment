class CfgVehicles
{
	class Logic;
	class Module_F: Logic
	{
		class AttributesBase
		{
			class Edit;
			class Checkbox;
			class Combo;
			class ModuleDescription;
		};
		class ModuleDescription {};
	};

	// MODULE ADD INTEL - Zeus dialog for planting one intel entry on the laptop under the module.
	class AE3_AddIntel: Module_F
	{
		scope = 1;
		scopeCurator = 2;
		displayName = "$STR_AE3_Desktop_Config_AddIntelDisplayName";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";

		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0; // server only
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;

		curatorInfoType = "AE3_UserInterface_Zeus_Module_AddIntel";

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleAddIntelDescription";
			sync[] = { "Land_Laptop_03_sand_F_AE3" };
		};
	};

	class AE3_AddEmail: Module_F
	{
		scope = 2;
		scopeCurator = 0;
		displayName = "AE3: Add Email";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";
		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;
		ae3_intelType = "email";

		class Attributes: AttributesBase
		{
			class AE3_ModuleIntel_From: Edit
			{
				property = "AE3_ModuleIntel_From";
				displayName = "From";
				typeName = "STRING";
				defaultValue = """informant@lan""";
			};
			class AE3_ModuleIntel_To: Edit
			{
				property = "AE3_ModuleIntel_To";
				displayName = "To";
				typeName = "STRING";
				defaultValue = """admin@lan""";
			};
			class AE3_ModuleIntel_Subject: Edit
			{
				property = "AE3_ModuleIntel_Subject";
				displayName = "Subject";
				typeName = "STRING";
				defaultValue = """Intel""";
			};
			class AE3_ModuleIntel_Body: Edit
			{
				property = "AE3_ModuleIntel_Body";
				displayName = "Body";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Received: Edit
			{
				property = "AE3_ModuleIntel_Received";
				displayName = "Received (HH:MM, blank = current)";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_CreateFrom: Checkbox
			{
				property = "AE3_ModuleIntel_CreateFrom";
				displayName = "Create sender address";
				typeName = "BOOL";
				defaultValue = 0;
			};
			class AE3_ModuleIntel_CreateTo: Checkbox
			{
				property = "AE3_ModuleIntel_CreateTo";
				displayName = "Create recipient address";
				typeName = "BOOL";
				defaultValue = 0;
			};
			class ModuleDescription: ModuleDescription{};
		};
	};

	class AE3_AddWebpage: Module_F
	{
		scope = 2;
		scopeCurator = 0;
		displayName = "AE3: Add Webpage";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";
		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;
		ae3_intelType = "webpage";

		class Attributes: AttributesBase
		{
			class AE3_ModuleIntel_Url: Edit
			{
				property = "AE3_ModuleIntel_Url";
				displayName = "URL";
				typeName = "STRING";
				defaultValue = """intel.root/page""";
			};
			class AE3_ModuleIntel_Title: Edit
			{
				property = "AE3_ModuleIntel_Title";
				displayName = "Title";
				typeName = "STRING";
				defaultValue = """Intel Page""";
			};
			class AE3_ModuleIntel_Content: Edit
			{
				property = "AE3_ModuleIntel_Content";
				displayName = "Content";
				typeName = "STRING";
				defaultValue = """""";
			};
			class ModuleDescription: ModuleDescription{};
		};
	};

	class AE3_AddBrowserHistory: Module_F
	{
		scope = 2;
		scopeCurator = 0;
		displayName = "AE3: Add Browser History";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";
		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;
		ae3_intelType = "history";

		class Attributes: AttributesBase
		{
			class AE3_ModuleIntel_Url: Edit
			{
				property = "AE3_ModuleIntel_Url";
				displayName = "URL";
				typeName = "STRING";
				defaultValue = """intel.root/page""";
			};
			class AE3_ModuleIntel_Time: Edit
			{
				property = "AE3_ModuleIntel_Time";
				displayName = "Time (HH:MM, blank = random)";
				typeName = "STRING";
				defaultValue = """""";
			};
			class ModuleDescription: ModuleDescription{};
		};
	};

	class AE3_AddMedia: Module_F
	{
		scope = 2;
		scopeCurator = 0;
		displayName = "AE3: Add Media";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";
		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;
		ae3_intelType = "media";

		class Attributes: AttributesBase
		{
			class AE3_ModuleIntel_Source: Edit
			{
				property = "AE3_ModuleIntel_Source";
				displayName = "Source path";
				typeName = "STRING";
				defaultValue = """media\images\mission.jpg""";
			};
			class AE3_ModuleIntel_MediaType: Combo
			{
				property = "AE3_ModuleIntel_MediaType";
				displayName = "Media type";
				typeName = "STRING";
				defaultValue = """image""";
				class Values
				{
					class Image { name = "Image"; value = "image"; };
					class Video { name = "Video"; value = "video"; };
					class Audio { name = "Audio"; value = "audio"; };
				};
			};
			class AE3_ModuleIntel_Dest: Edit
			{
				property = "AE3_ModuleIntel_Dest";
				displayName = "Laptop path";
				typeName = "STRING";
				defaultValue = """/home/admin/Desktop/media.jpg""";
			};
			class ModuleDescription: ModuleDescription{};
		};
	};

	class AE3_AddPasswordedFile: Module_F
	{
		scope = 2;
		scopeCurator = 0;
		displayName = "AE3: Add Passworded File";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";
		function = "AE3_desktop_fnc_module_addIntel";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;
		ae3_intelType = "lockedfile";

		class Attributes: AttributesBase
		{
			class AE3_ModuleIntel_Dest: Edit
			{
				property = "AE3_ModuleIntel_Dest";
				displayName = "Laptop path";
				typeName = "STRING";
				defaultValue = """/home/admin/Desktop/locked.txt""";
			};
			class AE3_ModuleIntel_Password: Edit
			{
				property = "AE3_ModuleIntel_Password";
				displayName = "Password";
				typeName = "STRING";
				defaultValue = """password""";
			};
			class AE3_ModuleIntel_Content: Edit
			{
				property = "AE3_ModuleIntel_Content";
				displayName = "Content";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Owner: Edit
			{
				property = "AE3_ModuleIntel_Owner";
				displayName = "Owner";
				typeName = "STRING";
				defaultValue = """root""";
			};
			class ModuleDescription: ModuleDescription{};
		};
	};

	// MODULE INTERFACE & ACCESS (Zeus only) - per-laptop interface mode plus per-player /
	// per-side CLI/GUI/Both access. Place it ON a laptop. Optional power-tool: by default
	// laptops already offer both interfaces with free switching (AE3_Desktop_DefaultMode).
	class AE3_InterfaceAccess: Module_F
	{
		scope = 1;        // Zeus only - not in the 3DEN module list (no player UIDs at edit time)
		scopeCurator = 2;
		displayName = "$STR_AE3_Desktop_Config_InterfaceAccessDisplayName";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";

		function = "AE3_desktop_fnc_module_interfaceAccess";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 0;
		isDisposable = 1;
		is3DEN = 0;

		curatorInfoType = "AE3_UserInterface_Zeus_Module_InterfaceAccess";

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleInterfaceAccessDescription";
		};
	};

	// MODULE CRASH DEVICE - crashes every synced AE3 laptop (blue screen until power-cycled).
	// No dialog; place/sync on a laptop and (optionally) gate behind a trigger.
	class AE3_CrashDevice: Module_F
	{
		scope = 2;
		scopeCurator = 2;
		displayName = "$STR_AE3_Desktop_Config_CrashDeviceDisplayName";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";

		function = "AE3_desktop_fnc_module_crashDevice";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleCrashDeviceDescription";
		};
	};
};

class CfgVehicles
{
	class Logic;
	class Module_F: Logic
	{
		class AttributesBase
		{
			class Edit;
			class ModuleDescription;
		};
		class ModuleDescription {};
	};

	// MODULE ADD INTEL - plants emails, webpages, browser history, calendar entries or media
	// on a laptop (place on a laptop) or on all laptops (place anywhere else)
	class AE3_AddIntel: Module_F
	{
		scope = 2;
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

		class Attributes: AttributesBase
		{
			// One dynamic control: a type dropdown whose visible fields follow the selected type.
			// The whole configuration is stored as a single serialized value (see fnc_intel_3denSave)
			// and read back by AE3_desktop_fnc_module_addIntel.
			class AE3_ModuleIntel_Data: Edit
			{
				property = "AE3_ModuleIntel_Data";
				displayName = "$STR_AE3_Desktop_Config_IntelTypeDisplayName";
				tooltip = "$STR_AE3_Desktop_Config_IntelTypeTooltip";
				control = "AE3_Intel3denControl";
				typeName = "STRING";
				defaultValue = """""";
				expression = "_this setVariable ['AE3_ModuleIntel_Data', _value];";
			};
			class ModuleDescription: ModuleDescription{};
		};

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleAddIntelDescription";
			sync[] = { "Land_Laptop_03_sand_F_AE3" };
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

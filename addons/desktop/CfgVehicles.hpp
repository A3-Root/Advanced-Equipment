class CfgVehicles
{
	class Logic;
	class Module_F: Logic
	{
		class AttributesBase
		{
			class Edit;
			class Checkbox;
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
			class AE3_ModuleIntel_Type: Edit
			{
				property = "AE3_ModuleIntel_Type";
				displayName = "$STR_AE3_Desktop_Config_IntelTypeDisplayName";
				tooltip = "$STR_AE3_Desktop_Config_IntelTypeTooltip";
				typeName = "STRING";
				defaultValue = """email""";
			};
			class AE3_ModuleIntel_Field1: Edit
			{
				property = "AE3_ModuleIntel_Field1";
				displayName = "$STR_AE3_Desktop_Config_IntelField1";
				tooltip = "$STR_AE3_Desktop_Config_IntelFieldsTooltip";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Field2: Edit
			{
				property = "AE3_ModuleIntel_Field2";
				displayName = "$STR_AE3_Desktop_Config_IntelField2";
				tooltip = "$STR_AE3_Desktop_Config_IntelFieldsTooltip";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Field3: Edit
			{
				property = "AE3_ModuleIntel_Field3";
				displayName = "$STR_AE3_Desktop_Config_IntelField3";
				tooltip = "$STR_AE3_Desktop_Config_IntelFieldsTooltip";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Field4: Edit
			{
				property = "AE3_ModuleIntel_Field4";
				displayName = "$STR_AE3_Desktop_Config_IntelField4";
				tooltip = "$STR_AE3_Desktop_Config_IntelFieldsTooltip";
				typeName = "STRING";
				defaultValue = """""";
			};
			class AE3_ModuleIntel_Owner: Edit
			{
				property = "AE3_ModuleIntel_Owner";
				displayName = "$STR_AE3_Desktop_Intel_LabelOwner";
				tooltip = "$STR_AE3_Desktop_Config_IntelFieldsTooltip";
				typeName = "STRING";
				defaultValue = """root""";
			};
			class AE3_ModuleIntel_OwnerRead: Checkbox
			{
				property = "AE3_ModuleIntel_OwnerRead";
				displayName = "$STR_AE3_Desktop_Intel_LabelOwnerRead";
				typeName = "BOOL";
				defaultValue = "true";
			};
			class AE3_ModuleIntel_OwnerWrite: Checkbox
			{
				property = "AE3_ModuleIntel_OwnerWrite";
				displayName = "$STR_AE3_Desktop_Intel_LabelOwnerWrite";
				typeName = "BOOL";
				defaultValue = "true";
			};
			class AE3_ModuleIntel_OwnerExecute: Checkbox
			{
				property = "AE3_ModuleIntel_OwnerExecute";
				displayName = "$STR_AE3_Desktop_Intel_LabelOwnerExecute";
				typeName = "BOOL";
				defaultValue = "false";
			};
			class AE3_ModuleIntel_EveryoneRead: Checkbox
			{
				property = "AE3_ModuleIntel_EveryoneRead";
				displayName = "$STR_AE3_Desktop_Intel_LabelEveryoneRead";
				typeName = "BOOL";
				defaultValue = "true";
			};
			class AE3_ModuleIntel_EveryoneWrite: Checkbox
			{
				property = "AE3_ModuleIntel_EveryoneWrite";
				displayName = "$STR_AE3_Desktop_Intel_LabelEveryoneWrite";
				typeName = "BOOL";
				defaultValue = "false";
			};
			class AE3_ModuleIntel_EveryoneExecute: Checkbox
			{
				property = "AE3_ModuleIntel_EveryoneExecute";
				displayName = "$STR_AE3_Desktop_Intel_LabelEveryoneExecute";
				typeName = "BOOL";
				defaultValue = "false";
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

	// MODULE ADD CAMERA - registers a CCTV feed for the desktop CCTV app. Sync it to (or place
	// it on) the object the camera view should originate from.
	class AE3_AddCamera: Module_F
	{
		scope = 2;
		scopeCurator = 2;
		displayName = "$STR_AE3_Desktop_Config_AddCameraDisplayName";
		icon = "\z\ae3\addons\armaos\ui\AE3_Module_Icons_addUser.paa";
		category = "AE3_armaosModules";

		function = "AE3_desktop_fnc_module_addCamera";
		functionPriority = 1;
		isGlobal = 0;
		isTriggerActivated = 1;
		isDisposable = 1;
		is3DEN = 0;

		curatorInfoType = "AE3_UserInterface_Zeus_Module_AddCamera";

		class Attributes: AttributesBase
		{
			class AE3_ModuleCamera_Name: Edit
			{
				property = "AE3_ModuleCamera_Name";
				displayName = "$STR_AE3_Desktop_Access_CameraName";
				tooltip = "$STR_AE3_Desktop_Access_CameraNameTooltip";
				typeName = "STRING";
				defaultValue = """Camera""";
			};
			class ModuleDescription: ModuleDescription{};
		};

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleAddCameraDescription";
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

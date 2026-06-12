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
			class ModuleDescription: ModuleDescription{};
		};

		class ModuleDescription: ModuleDescription
		{
			description = "$STR_AE3_Desktop_Config_ModuleAddIntelDescription";
			sync[] = { "Land_Laptop_03_sand_F_AE3" };
		};
	};
};

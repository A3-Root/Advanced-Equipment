#include "script_component.hpp"

class CfgPatches
{
    class ADDON
	{
        name = QUOTE(COMPONENT);
        units[] = { "AE3_AddIntel" };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"cba_main", "ace_main", "ae3_main", "ae3_armaos", "ae3_filesystem", "ae3_network"};
        author = "Root";
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "ui\RscAE3Desktop.hpp"
#include "CfgAE3Apps.hpp"
#include "CfgAE3Themes.hpp"
#include "CfgVehicles.hpp"
#include "\z\ae3\addons\main\defines.inc"
#include "CfgUserInterfaceZeus.hpp"

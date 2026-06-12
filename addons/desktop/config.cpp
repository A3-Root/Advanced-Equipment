#include "script_component.hpp"

class CfgPatches
{
    class ADDON
	{
        name = QUOTE(COMPONENT);
        units[] = {};
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

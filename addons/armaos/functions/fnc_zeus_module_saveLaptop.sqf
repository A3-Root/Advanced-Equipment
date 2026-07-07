#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Built-in curator prompt for the Save Laptop module, used when Zeus Enhanced is not
 * loaded. Runs on the placing curator's machine (reached via remoteExec from the server module
 * function). Stashes the module and synced-laptop netIds for the dialog to read, then opens the
 * built-in save-slot dialog. The dialog's onUnload sends the chosen slot back to the server through
 * AE3_armaos_fnc_module_saveLaptopApply.
 *
 * Arguments:
 * 0: _moduleNetId <STRING> - netId of the module logic
 * 1: _syncedNetIds <ARRAY> - netIds of the synced laptops
 *
 * Return Value:
 * None
 *
 * Example:
 * [_moduleNetId, _syncedNetIds] call AE3_armaos_fnc_zeus_module_saveLaptop;
 *
 * Public: No
 */

params ["_moduleNetId", "_syncedNetIds"];

uiNamespace setVariable ["AE3_armaos_saveLaptopArgs", [_moduleNetId, _syncedNetIds]];
createDialog "AE3_UserInterface_Zeus_Module_SaveLaptop";

// File: fnc_laptop_deploy_stable.sqf
/*
 * Author: Root
 * Description: Handles deploying a laptop using the stable method. Unhides the laptop object,
 * moves it in front of the player, enables simulation, and removes the dummy item.
 *
 * Arguments:
 * 0: _player <OBJECT> - The player deploying the laptop
 * 1: _item <STRING> (Optional) - Specific laptop item to deploy. If not provided, deploys the first one found.
 *
 * Return Value:
 * <BOOL> - True if deployment successful, false otherwise
 *
 * Example:
 * [player] call AE3_armaos_fnc_laptop_deploy_stable;
 * [player, "Item_Laptop_AE3_ID_5"] call AE3_armaos_fnc_laptop_deploy_stable;
 *
 * Public: No
 */

params ["_player", ["_item", ""]];

if (AE3_DebugMode) then {
	diag_log format ["[AE3 DEBUG] [%1] ========== laptop_deploy_stable CALLED by %2 ==========", time, _player];
};

// Get the laptop tracking hashmap
private _laptopTracker = missionNamespace getVariable ["AE3_LAPTOP_STABLE_TRACKER", createHashMap];

// Find laptop items in player's inventory
private _laptopItems = [];

{
	if (_x find "Item_Laptop_AE3_ID_" == 0) then {
		// Check if this item is tracked (stable mode item)
		if (_x in _laptopTracker) then {
			_laptopItems pushBack _x;
		};
	};
} forEach (items _player);

if (_laptopItems isEqualTo []) exitWith {
	hint "No laptop in inventory.";
	false
};

// Select which laptop to deploy
private _itemToDeploy = "";

if (_item != "" && _item in _laptopItems) then {
	// Deploy specific laptop if requested
	_itemToDeploy = _item;
} else {
	// Deploy first laptop found
	_itemToDeploy = _laptopItems select 0;
};

// Get the laptop object
private _laptop = _laptopTracker get _itemToDeploy;

if (isNil "_laptop" || {isNull _laptop}) exitWith {
	hint "Laptop object not found. This laptop may have been destroyed.";
	// Clean up the tracker
	_laptopTracker deleteAt _itemToDeploy;
	missionNamespace setVariable ["AE3_LAPTOP_STABLE_TRACKER", _laptopTracker, true];
	// Remove the item
	[_player, _itemToDeploy] call CBA_fnc_removeItem;
	false
};

if (AE3_DebugMode) then {
	diag_log format ["[AE3 DEBUG] [%1] laptop_deploy_stable: Deploying laptop %2 from item %3", time, _laptop, _itemToDeploy];
};

// Put the laptop down on the surface in front of the player rather than at terrain height, so a laptop
// deployed on an upper floor rests on that floor instead of dropping through the building.
private _deployPos = [_player] call AE3_armaos_fnc_laptop_deployPos;

if (AE3_DebugMode) then {
	diag_log format ["[AE3 DEBUG] [%1] laptop_deploy_stable: Deploying at position %2", time, _deployPos];
};

// Unhide and move the laptop
[_laptop, false] remoteExec ["hideObjectGlobal", 2];
_laptop setPosATL _deployPos;
[_laptop, true] remoteExec ["enableSimulationGlobal", 2];

// Remove the item from tracker
_laptopTracker deleteAt _itemToDeploy;
missionNamespace setVariable ["AE3_LAPTOP_STABLE_TRACKER", _laptopTracker, true];

// Remove the dummy item from player's inventory
[_player, _itemToDeploy] call CBA_fnc_removeItem;

// The laptop is out of the inventory and standing on the ground, so anything that was acting on it while
// it was packed away - a charger cabled to it, for one - has nothing to act on any more.
["AE3_laptop_removedFromInventory", [_player, _itemToDeploy]] call CBA_fnc_globalEvent;

// No deployment hint needed

if (AE3_DebugMode) then {
	diag_log format ["[AE3 DEBUG] [%1] ========== laptop_deploy_stable COMPLETE ==========", time];
};

true

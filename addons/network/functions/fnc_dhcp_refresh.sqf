/**
 * Refreshes the ip address for all network devices and router below
 * the given router.
 *
 * Arguments:
 * 0: Router <OBJECT>
 * 
 * Returns:
 * None
 *
 */

 params ["_entity"];

{

	if (isNil {_x getVariable "AE3_network_children"}) then
	{
		// Leaf device: hand out a fresh lease from this router's own subnet.
		_x setVariable ["AE3_network_address", [_entity] call AE3_network_fnc_dhcp_get, true];
	}
	else
	{
		// Child router: keep its own gateway/subnet, only refresh the devices below it.
		[_x] call AE3_network_fnc_dhcp_refresh;
	};

} forEach (_entity getVariable ["AE3_network_children", []]);

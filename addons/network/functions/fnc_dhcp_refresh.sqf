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
		// Leaf device: keep a configured static lease (per-router lease or the 3DEN static IP),
		// otherwise hand out a fresh lease from this router's own subnet. Without this, turning a
		// router on at mission start would refresh every client and wipe its static address.
		private _leases = _x getVariable ["AE3_network_staticIpByRouter", createHashMap];
		private _staticStr = _leases getOrDefault [netId _entity, ""];
		if (_staticStr isEqualTo "") then { _staticStr = _x getVariable ["AE3_network_staticIpDefault", ""]; };
		private _static = [_staticStr] call AE3_network_fnc_str2ip;
		if (_static isNotEqualTo [] && {!([_x, _static] call AE3_network_fnc_ipInUse)}) then
		{
			_x setVariable ["AE3_network_staticIp", _staticStr, true];
			_x setVariable ["AE3_network_address", _static, true];
		}
		else
		{
			_x setVariable ["AE3_network_address", [_entity] call AE3_network_fnc_dhcp_get, true];
		};
	}
	else
	{
		// Child router: keep its own gateway/subnet, only refresh the devices below it.
		[_x] call AE3_network_fnc_dhcp_refresh;
	};

} forEach (_entity getVariable ["AE3_network_children", []]);

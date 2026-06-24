/**
 * Connect a device to a router.
 *
 * Arguments:
 * 0: Device to connect <OBJECT>
 * 1: Parent router <OBJECT>
 *
 * Returns:
 * None
 */

params ["_device", "_parent"];

// A device belongs to exactly one router: drop any existing uplink before joining the new one so it
// cannot linger in a previous router's children list.
private _currentParent = _device getVariable ["AE3_network_parent", objNull];
if (!isNull _currentParent && {_currentParent isNotEqualTo _parent}) then
{
	[_device] call AE3_network_fnc_disconnect;
};

private _children = _parent getVariable ["AE3_network_children", []];
_parent setVariable ["AE3_network_children", _children + [_device], true];

_device setVariable ["AE3_network_parent", _parent, true];
if (isNull _parent) then
{
	_device setVariable ["AE3_network_address", [127, 0, 0, 1], true];
}
else
{
	// A configured static IP wins over DHCP; otherwise lease an address from the router's subnet. The
	// turn-on handler re-applies the same rule once the router is actually powered.
	private _static = [_device getVariable ["AE3_network_staticIp", ""]] call AE3_network_fnc_str2ip;
	if (_static isNotEqualTo []) then
	{
		_device setVariable ["AE3_network_address", _static, true];
	}
	else
	{
		_device setVariable ["AE3_network_address", [_parent] call AE3_network_fnc_dhcp_get, true];
	};
};

if (isNull _parent) then
{
    [_device, "networkConnected", false] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
}
else
{
    [_device, "networkConnected", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
    [_parent, "networkConnected", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
};

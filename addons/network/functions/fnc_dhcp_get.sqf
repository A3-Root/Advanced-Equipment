/**
 * Hands out a lease from a router's own subnet. Each router owns a single /24 and keeps its own
 * lease counter, so a device always receives an address inside the subnet of the router it is
 * connected to (the router's gateway address with an incrementing host octet). Routers are never
 * leased here; they keep the gateway address assigned during initialisation.
 *
 * Arguments:
 * 0: Router <OBJECT> - The router handing out the lease
 *
 * Returns:
 * 0: IP <[INT]>
 *
 */

params ["_entity"];

if (isNull _entity || {!alive _entity} || {(_entity getVariable ["AE3_power_powerState", 0]) == 0}) exitWith { [127, 0, 0, 1] };

private _counter = (_entity getVariable ["AE3_network_addressCounter", 0]) + 1;
_entity setVariable ["AE3_network_addressCounter", _counter, true];

private _address = _entity getVariable ["AE3_network_address", [192, 168, 0, 1]];

[
	_address select 0,
	_address select 1,
	_address select 2,
	((_address select 3) + _counter) % 256
];

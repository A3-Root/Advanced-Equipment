/*
 * Description: Checks whether another initialized laptop already owns an IP address.
 *
 * Arguments:
 * 0: _device <OBJECT> - Device requesting the address
 * 1: _ip <ARRAY> - Candidate address
 *
 * Return Value:
 * In use <BOOL>
 */

params ["_device", "_ip"];

private _computers = missionNamespace getVariable ["ae3_desktop_computers", []];
(_computers findIf {
	!isNull _x
	&& {_x isNotEqualTo _device}
	&& {_x getVariable ["AE3_cap_hasTerminal", false]}
	&& {(_x getVariable ["AE3_network_address", [127, 0, 0, 1]]) isEqualTo _ip}
}) >= 0

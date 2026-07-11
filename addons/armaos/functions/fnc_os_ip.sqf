// File: fnc_os_ip.sqf
#include "..\script_component.hpp"
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Displays the network configuration (linux style). Replaces the old windows-style
 * ipconfig command; available as both 'ip' and 'ifconfig'. 'ip a' / no argument shows the
 * device address, 'ip r' additionally shows the gateway (connected router).
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object
 * 1: _options <ARRAY> - Command options and arguments
 * 2: _commandName <STRING> - The name of the command
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer, [], "ip"] call AE3_armaos_fnc_os_ip;
 *
 * Public: Yes
 */

params ["_computer", "_options", "_commandName"];

private _commandOpts = [];
private _commandSyntax =
[
	[
			["command", _commandName, true, false]
	],
	[
			["command", _commandName, true, false],
			["path", "OBJECT", true, false]
	]
];
private _commandSettings = [_commandName, _commandOpts, _commandSyntax];

private _ae3OptsSuccess = false; private _ae3OptsThings = [];
[] params ([_computer, _options, _commandSettings] call AE3_armaos_fnc_shell_getOpts);

if (!_ae3OptsSuccess) exitWith {};

private _address = _computer getVariable "AE3_network_address";

if(isNil "_address") exitWith { [ _computer, localize "STR_AE3_ArmaOS_Exception_NoAddressDevice" ] call AE3_armaos_fnc_shell_stdout; };

[_computer, format [localize "STR_AE3_ArmaOS_Result_IPv4Address", [_address] call AE3_network_fnc_ip2str]] call AE3_armaos_fnc_shell_stdout;

// 'ip r' - additionally show the default gateway (connected router)
if (((_ae3OptsThings param [0, ""]) isEqualTo "r") || ((_ae3OptsThings param [0, ""]) isEqualTo "route")) then
{
	private _parent = _computer getVariable ["AE3_network_parent", objNull];

	if (isNull _parent) then
	{
		[_computer, localize "STR_AE3_ArmaOS_Result_NoGateway"] call AE3_armaos_fnc_shell_stdout;
	}
	else
	{
		private _gatewayAddress = _parent getVariable ["AE3_network_address", [127, 0, 0, 1]];
		[_computer, format [localize "STR_AE3_ArmaOS_Result_Gateway", [_gatewayAddress] call AE3_network_fnc_ip2str]] call AE3_armaos_fnc_shell_stdout;
	};
};

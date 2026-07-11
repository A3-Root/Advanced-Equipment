// File: fnc_os_ping.sqf
/*
 * Author: Root, y0014984, Wasserstoff
 * Description: Tests network connectivity to a specified IP address and displays round-trip time. Similar to Unix ping command.
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
 * [_computer, ["192.168.1.1"], "ping"] call AE3_armaos_fnc_os_ping;
 *
 * Public: Yes
 */

params ["_computer", "_options", "_commandName"];

private _commandOpts = [];
private _commandSyntax =
[
	[
			["command", _commandName, true, false],
			["path", "IP-ADDRESS", true, false]
	]
];
private _commandSettings = [_commandName, _commandOpts, _commandSyntax];

private _ae3OptsSuccess = false; private _ae3OptsThings = [];
[] params ([_computer, _options, _commandSettings] call AE3_armaos_fnc_shell_getOpts);

if (!_ae3OptsSuccess) exitWith {};

private _address = [_ae3OptsThings select 0] call AE3_network_fnc_str2ip;

if (_address isEqualTo []) exitWith { [_computer, localize "STR_AE3_ArmaOS_Exception_InvalidAddress"] call AE3_armaos_fnc_shell_stdout };

if (AE3_DebugMode || {missionNamespace getVariable ["AE3_NetworkDebugEnabled", false]}) then {
	diag_log text format ["[AE3][ROUTE] ping source=%1#%2 target=%3", [_computer, true] call ace_cargo_fnc_getNameItem, netId _computer, [_address] call AE3_network_fnc_ip2str];
};

private _result = [_computer, _address] call AE3_network_fnc_resolve;

if(isNull (_result select 0)) exitWith { [_computer, localize "STR_AE3_ArmaOS_Exception_PackageDropped"] call AE3_armaos_fnc_shell_stdout };

[ _computer, format [localize "STR_AE3_ArmaOS_Result_PingAnswer", _ae3OptsThings select 0, round ((_result select 1)/1e5)] ] call AE3_armaos_fnc_shell_stdout;

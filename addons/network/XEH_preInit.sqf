#include "script_component.hpp"
#include "XEH_PREP.hpp"

// Router turn-off requests from clients are routed to the server (see fnc_router_onTurnOff)
if (isServer) then
{
	["ae3_network_routerOff", { _this call AE3_network_fnc_router_onTurnOff }] call CBA_fnc_addEventHandler;

	// Instant messaging: append to the target's inbox and notify the active terminal user
	["ae3_network_imSend", {
		params ["_targetNetId", "_senderIp", "_text"];

		private _target = objectFromNetId _targetNetId;
		if (isNull _target) exitWith {};

		private _filesystem = _target getVariable ["AE3_filesystem", nil];
		if (isNil "_filesystem") exitWith {};

		private _line = format ["[%1] %2: %3", [dayTime, "HH:MM"] call BIS_fnc_timeToString, _senderIp, _text];

		try
		{
			// inbox is readable by everyone, writable by root only
			[[], _filesystem, "/var/mail", "root", "root", [[true, true, true], [true, false, true]]] call AE3_filesystem_fnc_ensureDir;
			[[], _filesystem, "/var/mail/inbox", "", "root", "root", [[true, true, false], [true, false, false]]] call AE3_filesystem_fnc_ensureFile;
			[[], _filesystem, "/var/mail/inbox", "root", _line + endl, true] call AE3_filesystem_fnc_writeToFile;
		}
		catch
		{
			WARNING_1("Could not deliver message: %1",_exception);
		};

		// Notify whoever is using the target terminal right now
		private _mutexHolder = _target getVariable ["AE3_computer_mutex", objNull];
		if (!isNull _mutexHolder && {_mutexHolder isKindOf "CAManBase"}) then
		{
			["ae3_network_imNotify", [_target, _senderIp], _mutexHolder] call CBA_fnc_targetEvent;
		};
	}] call CBA_fnc_addEventHandler;
};

// Client-side: show a notification in the open terminal when a message arrives
if (hasInterface) then
{
	["ae3_network_imNotify", {
		params ["_target", "_senderIp"];

		// Only show if this client actually has the target's terminal open
		private _display = findDisplay 15984;
		if (isNull _display) exitWith {};
		if ((_display getVariable ["AE3_computer", objNull]) isNotEqualTo _target) exitWith {};

		[_target, [[format [localize "STR_AE3_Network_Msg_Received", _senderIp], "#FFD966"]]] call AE3_armaos_fnc_shell_stdout;
	}] call CBA_fnc_addEventHandler;
};

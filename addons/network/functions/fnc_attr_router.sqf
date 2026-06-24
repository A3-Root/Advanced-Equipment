/**
 * Eden object-attribute helper for routers. Applies one wireless setting (network name, gateway,
 * range or password) once the router has finished initialising, so the values entered in the 3DEN
 * attribute editor take effect at mission start regardless of init ordering. A blank gateway/name
 * leaves the auto-assigned value untouched. Server-side.
 *
 * Arguments:
 * 0: Router <OBJECT>
 * 1: Key <STRING> - "ssid" | "gateway" | "range" | "password" | "extssh" | "extallow" | "starton"
 * 2: Value <STRING|NUMBER|BOOL> - Setting value from the attribute
 *
 * Returns:
 * None
 */

params ["_router", ["_key", ""], ["_value", ""]];

if (!isServer) exitWith {};

[
	{ params ["_router"]; !isNull _router && {_router getVariable ["AE3_cap_isRouter", false]} },
	{
		params ["_router", "_key", "_value"];
		switch (_key) do
		{
			case "gateway":
			{
				private _gw = [_value] call AE3_network_fnc_str2ip;
				if (_gw isNotEqualTo []) then { _router setVariable ["AE3_network_address", _gw, true]; };
			};
			case "range":      { if (_value > 0) then { _router setVariable ["AE3_network_wirelessRange", _value, true]; }; };
			case "password":   { _router setVariable ["AE3_network_password", _value, true]; };
			case "ssid":       { if (_value isNotEqualTo "") then { _router setVariable ["ace_cargo_customName", _value, true]; }; };
			case "extssh":     { _router setVariable ["AE3_network_allowExternalSsh", _value, true]; };
			case "extallow":   { _router setVariable ["AE3_network_externalAllow", _value, true]; };
			case "starton":
			{
				// Coerce to a strict boolean: a checkbox attribute may arrive as a Number, which would
				// otherwise break the boolean checks below and skip the auto power-on entirely.
				private _startOn = _value isEqualTo true;
				_router setVariable ["AE3_power_startOn", _startOn, true];
				if (AE3_DebugMode) then { diag_log format ["[AE3 DEBUG] [%1] attr_router starton on %2: value=%3", time, _router, _startOn]; };
				if (_startOn) then
				{
					// Power the router on only once its power initialisation is fully complete
					// (AE3_power_initDone covers the device and its internal battery), so the turn-on
					// never runs against a half-initialised device.
					[
						{
							params ["_router"];
							!alive _router || {
								_router getVariable ["AE3_power_initDone", false] &&
								{!isNil {_router getVariable "AE3_power_fnc_turnOnWrapper"}}
							}
						},
						{
							params ["_router"];
							if (alive _router && {(_router getVariable ["AE3_power_powerState", 0]) != 1}) then
							{
								private _ok = [_router] call AE3_power_fnc_turnOnDevice;
								if (AE3_DebugMode) then { diag_log format ["[AE3 DEBUG] [%1] attr_router auto power-on %2: turnOnDevice=%3", time, _router, _ok]; };
							};
						},
						[_router]
					] call CBA_fnc_waitUntilAndExecute;
				};
			};
		};
	},
	[_router, _key, _value]
] call CBA_fnc_waitUntilAndExecute;

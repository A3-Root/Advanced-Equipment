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
				_router setVariable ["AE3_power_startOn", _value, true];
				if (_value) then
				{
					// Power the router on once its power device has finished initialising.
					[
						{ params ["_router"]; !alive _router || {!isNil {_router getVariable "AE3_power_fnc_turnOnWrapper"}} },
						{
							params ["_router"];
							if (alive _router && {(_router getVariable ["AE3_power_powerState", 0]) != 1}) then
							{
								[_router] call AE3_power_fnc_turnOnDevice;
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

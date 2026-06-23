/**
 * Returns the device object and the route length for given initial device and
 * target IP. Returns objNull if route is invalid.
 *
 *
 * Arguments:
 * 0: Device <OBJECT>
 * 1: Target IP <[INT]>
 * 2: Last Hopp <OBJECT> (Optional)
 *
 * Returns:
 * 0: Target <OBJECT>
 * 1: Length <FLOAT>
 */

params ["_entity", "_target", ["_last", objNull]];

if (!alive _entity || _entity getVariable ["AE3_power_powerState", 1] == 0) exitWith
{
	[objNull, 0];
};

if (_target isEqualTo [127, 0, 0, 1] || _target isEqualTo (_entity getVariable "AE3_network_address")) exitWith
{
	[_entity, 0];
};

// Is router? 
if (!isNil {_entity getVariable "AE3_network_children"}) exitWith
{
	private _catch = _entity getVariable "AE3_network_addressCatch";

	// Target is in catch
	private _result = [objNull, 0];
	if (([_target] call AE3_network_fnc_ip2str) in _catch) then
	{
		private _next = _catch get ([_target] call AE3_network_fnc_ip2str);
		private _res = [_next, _target, _entity] call AE3_network_fnc_ping;

		if (isNull (_res select 0)) exitWith
		{
			_catch deleteAt ([_target] call AE3_network_fnc_ip2str);
			_entity setVariable ["AE3_network_addressCatch", _catch, true];
			_result = _res;
		};
		private _len = (_res select 1) + (_next distance _entity);
		_res set [1, _len];
		_result = _res;
	};
	if (!isNull (_result select 0)) exitWith {_result};

	// Target is in children
	_result = {
		if (_x isEqualTo _last) then {continue};

		private _res = [_x, _target, _entity] call AE3_network_fnc_ping;

		if (!isNull (_res select 0)) exitWith
		{
			_catch set [([_target] call AE3_network_fnc_ip2str), _x];
			_entity setVariable ["AE3_network_addressCatch", _catch, true];

			private _len = (_res select 1) + (_x distance _entity);
			_res set [1, _len];
			_res;
		};
	} forEach (_entity getVariable ["AE3_network_children", []]);

	if (!isNil "_result") exitWith {_result};

	// Target is in parents
	_result = [objNull, 0];
	private _parent = _entity getVariable ["AE3_network_parent", objNull];
	if (!isNull (_parent) && (_parent isNotEqualTo _last)) then
	{
		private _res = [_parent, _target, _entity] call AE3_network_fnc_ping;

		if (!isNull(_res select 0)) then
		{
			_catch set [([_target] call AE3_network_fnc_ip2str), _parent];
			_entity setVariable ["AE3_network_addressCatch", _catch, true];

			private _len = (_res select 1) + (_parent distance _entity);
			_res set [1, _len];
			_result = _res;
		};
	};

	_result;
};

private _parent = _entity getVariable ["AE3_network_parent", objNull];
if (!isNull _parent && (_parent isNotEqualTo _last)) exitWith
{
	private _res = [_parent, _target, _entity] call AE3_network_fnc_ping;
	private _len = (_parent distance _entity) + (_res select 1);
	_res set [1, _len];
	_res;
};

[objNull, 0];

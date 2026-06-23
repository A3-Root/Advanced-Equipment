/**
 * Returns the device object and the route length for given initial device and
 * target IP. Returns objNull if route is invalid.
 *
 *
 * Arguments:
 * 0: Device <OBJECT>
 * 1: Target IP <[INT]>
 * 2: Last hop <OBJECT> (Optional)
 * 3: Visited devices <ARRAY> (Optional)
 *
 * Returns:
 * 0: Target <OBJECT>
 * 1: Length <FLOAT>
 */

params ["_entity", "_target", ["_last", objNull], ["_visited", [], [[]]]];

if (isNull _entity || {_entity in _visited}) exitWith
{
	[objNull, 0];
};

_visited pushBack _entity;

if (!alive _entity || _entity getVariable ["AE3_power_powerState", 1] == 0) exitWith
{
	[objNull, 0];
};

if (_target isEqualTo [127, 0, 0, 1] || _target isEqualTo (_entity getVariable ["AE3_network_address", [127, 0, 0, 1]])) exitWith
{
	[_entity, 0];
};

// Routers can forward to cached next hops, children, or their parent router.
if (!isNil {_entity getVariable "AE3_network_children"}) exitWith
{
	private _catch = _entity getVariable ["AE3_network_addressCatch", createHashMap];
	private _targetStr = [_target] call AE3_network_fnc_ip2str;

	private _result = [objNull, 0];
	if (_targetStr in _catch) then
	{
		private _next = _catch get _targetStr;
		private _res = [_next, _target, _entity, +_visited] call AE3_network_fnc_ping;

		if (isNull (_res select 0)) then
		{
			_catch deleteAt _targetStr;
			_entity setVariable ["AE3_network_addressCatch", _catch, true];
		}
		else
		{
			_res set [1, (_res select 1) + (_next distance _entity)];
			_result = _res;
		};
	};
	if (!isNull (_result select 0)) exitWith {_result};

	{
		if (_x isEqualTo _last || {_x in _visited}) then {continue};

		private _res = [_x, _target, _entity, +_visited] call AE3_network_fnc_ping;

		if (!isNull (_res select 0)) then
		{
			_catch set [_targetStr, _x];
			_entity setVariable ["AE3_network_addressCatch", _catch, true];

			_res set [1, (_res select 1) + (_x distance _entity)];
			_result = _res;
		};
	} forEach (_entity getVariable ["AE3_network_children", []]);

	if (!isNull (_result select 0)) exitWith {_result};

	private _parent = _entity getVariable ["AE3_network_parent", objNull];
	if (!isNull _parent && {_parent isNotEqualTo _last} && {!(_parent in _visited)}) then
	{
		private _res = [_parent, _target, _entity, +_visited] call AE3_network_fnc_ping;

		if (!isNull (_res select 0)) then
		{
			_catch set [_targetStr, _parent];
			_entity setVariable ["AE3_network_addressCatch", _catch, true];

			_res set [1, (_res select 1) + (_parent distance _entity)];
			_result = _res;
		};
	};

	_result;
};

private _parent = _entity getVariable ["AE3_network_parent", objNull];
if (!isNull _parent && {_parent isNotEqualTo _last} && {!(_parent in _visited)}) exitWith
{
	private _res = [_parent, _target, _entity, +_visited] call AE3_network_fnc_ping;
	if (!isNull (_res select 0)) then
	{
		_res set [1, (_parent distance _entity) + (_res select 1)];
	};
	_res;
};

[objNull, 0];

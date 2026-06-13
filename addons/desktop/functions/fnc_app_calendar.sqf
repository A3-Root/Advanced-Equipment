#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Desktop "Calendar" app: month grid of the in-game date with event markers.
 * Events come from /home/user/calendar, one per line: "YYYY-MM-DD [HH:MM] | TITLE | DETAILS".
 * Days with events are highlighted; clicking a day shows its events. Prev/next month buttons.
 * Entries are plantable intel: AE3_desktop_fnc_addCalendarEvent, Zeus AddIntel/AddFile, notepad.
 *
 * Arguments:
 * 0: _winId <NUMBER>
 * 1: _ctrlGroup <CONTROL>
 * 2: _computer <OBJECT>
 * 3: _args <ANY>
 *
 * Return Value:
 * App callbacks <HASHMAP>
 *
 * Public: No
 */

params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _session = uiNamespace getVariable ["AE3_desktop_session", createHashMap];
private _display = _session getOrDefault ["display", displayNull];
private _theme = _session getOrDefault ["theme", createHashMap];

(ctrlPosition _ctrlGroup) params ["", "", "_w", "_h"];

/* month header: prev / title / next */
private _prevBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_prevBtn ctrlSetPosition [0.01, 0.045, 0.05, 0.035];
_prevBtn ctrlSetText "<";
_prevBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_prevBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_prevBtn ctrlCommit 0;

private _monthCtrl = _display ctrlCreate ["RscText", -1, _ctrlGroup];
_monthCtrl ctrlSetPosition [0.07, 0.045, _w - 0.14, 0.035];
_monthCtrl ctrlSetTextColor (_theme getOrDefault ["accent", [1,1,1,1]]);
_monthCtrl ctrlCommit 0;

private _nextBtn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
_nextBtn ctrlSetPosition [_w - 0.06, 0.045, 0.05, 0.035];
_nextBtn ctrlSetText ">";
_nextBtn ctrlSetBackgroundColor (_theme getOrDefault ["titlebar", [0,0,0,1]]);
_nextBtn ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]);
_nextBtn ctrlCommit 0;

/* details pane (bottom third) */
private _detailsCtrl = _display ctrlCreate ["RscStructuredText", -1, _ctrlGroup];
_detailsCtrl ctrlSetPosition [0.01, _h - (_h * 0.32), _w - 0.02, _h * 0.31];
_detailsCtrl ctrlCommit 0;

/* ---------------------------------------- */

date params ["_year", "_month"];

// Restored session: re-open the month the previous user was looking at
(_args param [0, [_year, _month]]) params [["_stateYear", _year], ["_stateMonth", _month]];

_monthCtrl setVariable ["AE3_state", [_stateYear, _stateMonth]];
_monthCtrl setVariable ["AE3_computer", _computer];
_monthCtrl setVariable ["AE3_ctx", [_display, _ctrlGroup, _theme, _w, _h, _detailsCtrl]];
_monthCtrl setVariable ["AE3_dayCtrls", []];

private _render = {
	params ["_monthCtrl"];

	(_monthCtrl getVariable "AE3_state") params ["_year", "_month"];
	(_monthCtrl getVariable "AE3_ctx") params ["_display", "_ctrlGroup", "_theme", "_w", "_h", "_detailsCtrl"];
	private _computer = _monthCtrl getVariable "AE3_computer";

	_monthCtrl ctrlSetText format ["%1 - %2", _year, [_month, 2] call CBA_fnc_formatNumber];

	// clear previous grid
	{ ctrlDelete _x; } forEach (_monthCtrl getVariable "AE3_dayCtrls");

	// collect events of this month from the calendar file: day -> [event lines]
	private _events = createHashMap;
	private _filesystem = _computer getVariable ["AE3_filesystem", []];
	try
	{
		private _content = [[], _filesystem, "/home/user/calendar", "root", 0] call AE3_filesystem_fnc_getFile;
		if (_content isEqualType "") then
		{
			private _prefix = format ["%1-%2-", _year, [_month, 2] call CBA_fnc_formatNumber];
			{
				private _line = [_x] call CBA_fnc_trim;
				if ((_line select [0, count _prefix]) isEqualTo _prefix) then
				{
					private _day = parseNumber (_line select [count _prefix, 2]);
					if (_day > 0) then
					{
						private _list = _events getOrDefault [_day, [], true];
						_list pushBack _line;
					};
				};
			} forEach (_content splitString endl);
		};
	}
	catch {};

	// days in month (leap-year aware)
	private _daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] select (_month - 1);
	if (_month == 2 && {(_year mod 4 == 0 && _year mod 100 != 0) || _year mod 400 == 0}) then { _daysInMonth = 29; };

	date params ["_curYear", "_curMonth", "_curDay"];

	private _gridTop = 0.09;
	private _gridH = _h - (_h * 0.34) - _gridTop;
	private _cellW = (_w - 0.02) / 7;
	private _cellH = _gridH / 6;

	private _dayCtrls = [];
	for "_day" from 1 to _daysInMonth do
	{
		private _index = _day - 1;
		private _btn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
		_btn ctrlSetPosition [
			0.01 + _cellW * (_index mod 7),
			_gridTop + _cellH * floor (_index / 7),
			_cellW - 0.004,
			_cellH - 0.004
		];
		_btn ctrlSetText str _day;

		private _hasEvents = _day in _events;
		private _isToday = (_year == _curYear) && (_month == _curMonth) && (_day == _curDay);

		_btn ctrlSetBackgroundColor (switch (true) do
		{
			case (_isToday):   { _theme getOrDefault ["accent", [0.2,0.5,0.8,1]] };
			case (_hasEvents): { _theme getOrDefault ["titlebar", [0.3,0.3,0.3,1]] };
			default            { _theme getOrDefault ["window", [0.1,0.1,0.1,1]] };
		});
		_btn ctrlSetTextColor ([_theme getOrDefault ["text", [1,1,1,1]], [1, 0.85, 0.4, 1]] select _hasEvents);
		_btn ctrlCommit 0;

		_btn setVariable ["AE3_ctx", [_detailsCtrl, _events getOrDefault [_day, []], _year, _month, _day]];
		_btn ctrlAddEventHandler ["ButtonClick", {
			params ["_btn"];
			((_btn getVariable "AE3_ctx")) params ["_detailsCtrl", "_dayEvents", "_year", "_month", "_day"];

			private _lines = [format ["<t size='1.2' color='#5da8e8'>%1-%2-%3</t>", _year, [_month, 2] call CBA_fnc_formatNumber, [_day, 2] call CBA_fnc_formatNumber]];
			if (_dayEvents isEqualTo []) then
			{
				_lines pushBack (localize "STR_AE3_Desktop_Calendar_NoEvents");
			}
			else
			{
				{
					(_x splitString "|") params [["_date", ""], ["_title", ""], ["_details", ""]];
					_lines pushBack format ["<t color='#ffd966'>%1</t>  %2<br/><t color='#aaaaaa'>%3</t>", [_date] call CBA_fnc_trim, [_title] call CBA_fnc_trim, [_details] call CBA_fnc_trim];
				} forEach _dayEvents;
			};
			_detailsCtrl ctrlSetStructuredText (parseText (_lines joinString "<br/>"));
		}];

		_dayCtrls pushBack _btn;
	};

	_monthCtrl setVariable ["AE3_dayCtrls", _dayCtrls];
};

_monthCtrl setVariable ["AE3_render", _render];
[_monthCtrl] call _render;

/* ---------------------------------------- */

_prevBtn setVariable ["AE3_monthCtrl", _monthCtrl];
_prevBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _monthCtrl = _button getVariable "AE3_monthCtrl";
	(_monthCtrl getVariable "AE3_state") params ["_year", "_month"];
	_month = _month - 1;
	if (_month < 1) then { _month = 12; _year = _year - 1; };
	_monthCtrl setVariable ["AE3_state", [_year, _month]];
	[_monthCtrl] call (_monthCtrl getVariable "AE3_render");
}];

_nextBtn setVariable ["AE3_monthCtrl", _monthCtrl];
_nextBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_button"];
	private _monthCtrl = _button getVariable "AE3_monthCtrl";
	(_monthCtrl getVariable "AE3_state") params ["_year", "_month"];
	_month = _month + 1;
	if (_month > 12) then { _month = 1; _year = _year + 1; };
	_monthCtrl setVariable ["AE3_state", [_year, _month]];
	[_monthCtrl] call (_monthCtrl getVariable "AE3_render");
}];

createHashMapFromArray [
	["monthCtrl", _monthCtrl],
	["getState", {
		private _ctrl = _this getOrDefault ["monthCtrl", controlNull];
		if (isNull _ctrl) exitWith { [] };
		[+ (_ctrl getVariable ["AE3_state", []])]
	}]
]

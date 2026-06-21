#include "script_component.hpp"

// Seed a default Browser homepage (RootNet index) on the server so the in-game browser is never
// empty. Mission makers register additional pages with AE3_desktop_fnc_registerWebpage; those
// appear automatically on home.root alongside this welcome entry.
if (isServer) then
{
	[
		"rootnet.root",
		"RootNet",
		[
			"<t size='1.2'>Welcome to RootNet</t>",
			"",
			"The internal network index. Pages published on this network appear on the home screen.",
			"",
			"Type an address in the bar above, or pick a link below.",
			"",
			"[[home.root|Home]]"
		]
	] call AE3_desktop_fnc_registerWebpage;
};

// Web Messenger: server pushes the laptop's IM inbox text here; forward it to the open browser.
if (hasInterface) then
{
	["ae3_desktop_chatData", {
		params ["_text"];
		["chat_data", createHashMapFromArray [["text", _text]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// Calendar store changed on the server (Zeus/Eden module or in-app add/delete): nudge the open
	// web Calendar to re-pull AE3_calendar_events so module-added events appear without a manual
	// refresh (#4). No-op when no desktop is open or the Calendar app is not subscribed.
	["ae3_desktop_calChanged", {
		["cal_changed", []] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// Wireless connect result (#14): forward the server's verdict (ok + message) to the Network app.
	["ae3_desktop_netResult", {
		params ["_ok", "_msg"];
		["net_result", createHashMapFromArray [["ok", _ok], ["msg", _msg]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;
};

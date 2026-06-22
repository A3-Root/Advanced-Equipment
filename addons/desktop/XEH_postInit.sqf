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

	// SSH client ops run on the server (authoritative filesystems + auth).
	["ae3_desktop_sshOp", { _this call AE3_desktop_fnc_sshOpServer }] call CBA_fnc_addEventHandler;
};

// Web Messenger: server pushes the laptop's IM inbox text here; forward it to the open browser.
if (hasInterface) then
{
	["ae3_desktop_chatData", {
		params ["_threads"];
		// Threads: [[peerIp, [[dir,time,text], ...]], ...] -> structured payload for the Messenger app.
		private _out = [];
		{
			_x params ["_peer", "_msgs"];
			private _jmsgs = [];
			{
				_x params ["_dir", "_time", "_text"];
				_jmsgs pushBack createHashMapFromArray [["dir", _dir], ["time", _time], ["text", _text]];
			} forEach _msgs;
			_out pushBack createHashMapFromArray [["peer", _peer], ["messages", _jmsgs]];
		} forEach _threads;
		["chat_data", createHashMapFromArray [["threads", _out]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	["ae3_desktop_routeReply", {
		params ["_rid", "_cmd", "_payload"];
		[_cmd, createHashMapFromArray [["_rid", _rid], ["data", _payload]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	["ae3_desktop_msgNotify", {
		params ["_peer"];
		["msg_notify", createHashMapFromArray [["peer", _peer]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// Calendar store changed on the server (Zeus/Eden module or in-app add/delete): nudge the open
	// web Calendar to re-pull AE3_calendar_events so module-added events appear without a manual
	// refresh. No-op when no desktop is open or the Calendar app is not subscribed.
	["ae3_desktop_calChanged", {
		["cal_changed", []] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// SSH server reply: forward to the SSH app, echoing the rid so its A3.request resolves.
	["ae3_desktop_sshReply", {
		params ["_owner", "_rid", "_cmd", "_payload"];
		[_cmd, createHashMapFromArray [["_rid", _rid], ["data", _payload]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// USB volume change (connect/auto-mount): nudge an open My Computer app to refresh.
	["ae3_desktop_volChanged", {
		["vol_changed", []] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;

	// Wireless connect result: forward the server's verdict (ok + message) to the Network app.
	["ae3_desktop_netResult", {
		params ["_ok", "_msg"];
		["net_result", createHashMapFromArray [["ok", _ok], ["msg", _msg]]] call AE3_desktop_fnc_jsSend;
	}] call CBA_fnc_addEventHandler;
};

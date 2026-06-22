#include "script_component.hpp"
#include "XEH_PREP.hpp"

/* ================================================================================ */
/* CBA settings */

[
	"AE3_Desktop_DefaultMode",
	"LIST",
	["Default laptop interface", "Interface offered by laptops that have no explicit per-laptop setting. CLI = classic terminal, GUI = desktop, Both = laptop offers both and players freely switch between them."],
	"AE3 Desktop",
	[
		["cli", "gui", "both"],
		[["CLI", "CLI"], ["GUI", "GUI"], ["Both (CLI + GUI)", "Both (CLI + GUI)"]],
		2
	],
	1,
	{ params ["_value"]; },
	false
] call CBA_fnc_addSetting;

[
	"AE3_Desktop_EnableDragDrop",
	"CHECKBOX",
	["Window dragging", "Allow moving desktop windows by dragging their titlebar."],
	"AE3 Desktop",
	true,
	1,
	{ params ["_value"]; },
	false
] call CBA_fnc_addSetting;

[
	"AE3_Desktop_EnableFileBrowsing",
	"CHECKBOX",
	["File browsing", "Allow browsing the laptop filesystem with the Files app."],
	"AE3 Desktop",
	true,
	1,
	{ params ["_value"]; },
	false
] call CBA_fnc_addSetting;

[
	"AE3_Desktop_DefaultTheme",
	"LIST",
	["Default theme", "Default desktop theme for laptops without a per-laptop selection."],
	"AE3 Desktop",
	[
		["Dark", "Light", "Olive"],
		[["Dark", "Dark"], ["Light", "Light"], ["Olive", "Olive"]],
		0
	],
	1,
	{ params ["_value"]; },
	false
] call CBA_fnc_addSetting;

/* ================================================================================ */
/* Server: computer registry + media registry */

if (isServer) then
{
	ae3_desktop_computers = [];
	ae3_desktop_pendingMedia = []; // [_sourcePath, _type, _fsDest] entries applied to future laptops

	// Emitted by AE3_armaos_fnc_device_initComplete after a computer finished initializing
	["ae3_armaos_deviceReady", {
		params ["_computer"];

		ae3_desktop_computers pushBackUnique _computer;

		// Give the laptop a default mail address + Messenger handle so messaging works immediately.
		[_computer] call AE3_desktop_fnc_provisionIdentity;

		// Apply media registered for "future" laptops
		{
			_x params ["_sourcePath", "_type", "_fsDest"];
			[_sourcePath, _type, _fsDest, [_computer]] call AE3_desktop_fnc_registerMedia;
		} forEach ae3_desktop_pendingMedia;
	}] call CBA_fnc_addEventHandler;

	// Client-routed media registration
	["ae3_desktop_registerMedia", { _this call AE3_desktop_fnc_registerMedia }] call CBA_fnc_addEventHandler;

	// Client-routed interface mode changes
	["ae3_desktop_setInterfaceMode", { _this call AE3_desktop_fnc_setInterfaceMode }] call CBA_fnc_addEventHandler;
	["ae3_desktop_setInterfaceAccess", { _this call AE3_desktop_fnc_setInterfaceAccess }] call CBA_fnc_addEventHandler;

	// Client-routed intel APIs (email, webpages, browser history, calendar)
	["ae3_desktop_addEmail", { _this call AE3_desktop_fnc_addEmail }] call CBA_fnc_addEventHandler;
	["ae3_desktop_registerWebpage", { _this call AE3_desktop_fnc_registerWebpage }] call CBA_fnc_addEventHandler;
	["ae3_desktop_addHistoryEntry", { _this call AE3_desktop_fnc_addHistoryEntry }] call CBA_fnc_addEventHandler;
	["ae3_desktop_addCalendarEvent", { _this call AE3_desktop_fnc_addCalendarEvent }] call CBA_fnc_addEventHandler;
	["ae3_desktop_registerCamera", { _this call AE3_desktop_fnc_registerCamera }] call CBA_fnc_addEventHandler;
	["ae3_desktop_addLockedFile", { _this call AE3_desktop_fnc_addLockedFile }] call CBA_fnc_addEventHandler;

	// Web Messenger: client requests its laptop's live IM inbox
	["ae3_desktop_chatPull", { _this call AE3_desktop_fnc_chatPullServer }] call CBA_fnc_addEventHandler;
	["ae3_desktop_handleRegister", { _this call AE3_desktop_fnc_handleRegister }] call CBA_fnc_addEventHandler;
	["ae3_desktop_handleRelease", { _this call AE3_desktop_fnc_handleRelease }] call CBA_fnc_addEventHandler;
	["ae3_desktop_msgRoute", { _this call AE3_desktop_fnc_msgRoute }] call CBA_fnc_addEventHandler;
	["ae3_desktop_addrRegister", { _this call AE3_desktop_fnc_addrRegister }] call CBA_fnc_addEventHandler;
	["ae3_desktop_addrRelease", { _this call AE3_desktop_fnc_addrRelease }] call CBA_fnc_addEventHandler;
	["ae3_desktop_mailRoute", { _this call AE3_desktop_fnc_mailRoute }] call CBA_fnc_addEventHandler;
	["ae3_desktop_sshOp", { _this call AE3_desktop_fnc_sshOpServer }] call CBA_fnc_addEventHandler;
};

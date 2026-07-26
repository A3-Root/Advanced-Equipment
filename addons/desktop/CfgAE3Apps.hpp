// AE3 desktop application registry.
//
// Third-party mods register their own apps by adding a class to CfgAE3Apps (or at runtime via
// AE3_desktop_fnc_registerApp). The entry function is called as:
//   [_winId, _ctrlGroup, _computer, _args] call (missionNamespace getVariable entry);
// and may return a HASHMAP with optional "onClose" / "onFocus" CODE callbacks.
// See wiki/Developer/Extending-Desktop-GUI.md for the full developer documentation.

class AE3_DesktopApp
{
	displayName = "App";
	entry = "";              // function name (STRING), resolved via missionNamespace
	icon = "";               // optional icon text/path (currently rendered as a text button)
	defaultSize[] = {0.5, 0.5}; // window size as fraction of the desktop area
	showOnDesktop = 1;       // 1 = desktop icon is created
	singleton = 1;           // 1 = only one window instance at a time
	requiresFilesystem = 1;  // 1 = app needs the laptop filesystem
};

class CfgAE3Apps
{
	class Terminal : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Terminal";
		entry = "AE3_desktop_fnc_app_terminal";
		defaultSize[] = {0.7, 0.7};
	};

	class Files : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Files";
		entry = "AE3_desktop_fnc_app_files";
		defaultSize[] = {0.55, 0.65};
	};

	class Settings : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Settings";
		entry = "AE3_desktop_fnc_app_settings";
		defaultSize[] = {0.4, 0.6};
	};

	class Notepad : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Notepad";
		entry = "AE3_desktop_fnc_app_notepad";
		defaultSize[] = {0.5, 0.6};
		singleton = 0; // multiple notes at once
	};

	class Mail : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Mail";
		entry = "AE3_desktop_fnc_app_mail";
		defaultSize[] = {0.65, 0.6};
	};

	class Chat : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Chat";
		entry = "AE3_desktop_fnc_app_chat";
		defaultSize[] = {0.5, 0.55};
	};

	class Browser : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Browser";
		entry = "AE3_desktop_fnc_app_browser";
		defaultSize[] = {0.65, 0.7};
	};

	class Calendar : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Calendar";
		entry = "AE3_desktop_fnc_app_calendar";
		defaultSize[] = {0.5, 0.65};
	};

	class MapApp : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Map";
		entry = "AE3_desktop_fnc_app_map";
		defaultSize[] = {0.7, 0.75};
	};

	class Cctv : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Cctv";
		entry = "AE3_desktop_fnc_app_cctv";
		defaultSize[] = {0.6, 0.65};
	};

	class Music : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_Music";
		entry = "AE3_desktop_fnc_app_music";
		defaultSize[] = {0.45, 0.55};
	};

	class SysInfo : AE3_DesktopApp
	{
		displayName = "$STR_AE3_Desktop_App_SysInfo";
		entry = "AE3_desktop_fnc_app_sysinfo";
		defaultSize[] = {0.4, 0.5};
	};
};

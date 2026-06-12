// AE3 desktop theme registry. Colors are RGBA arrays (0..1).
// Additional themes can be added by mods/missions via config.

class AE3_DesktopTheme
{
	displayName = "Theme";
	wallpaperColor[] = {0.08, 0.10, 0.12, 1};
	panelColor[] = {0.05, 0.05, 0.06, 0.95};
	windowColor[] = {0.12, 0.13, 0.15, 0.98};
	titlebarColor[] = {0.18, 0.20, 0.24, 1};
	accentColor[] = {0.20, 0.55, 0.85, 1};
	textColor[] = {0.92, 0.92, 0.92, 1};
};

class CfgAE3Themes
{
	class Dark : AE3_DesktopTheme
	{
		displayName = "$STR_AE3_Desktop_Theme_Dark";
	};

	class Light : AE3_DesktopTheme
	{
		displayName = "$STR_AE3_Desktop_Theme_Light";
		wallpaperColor[] = {0.75, 0.78, 0.80, 1};
		panelColor[] = {0.88, 0.88, 0.90, 0.95};
		windowColor[] = {0.94, 0.94, 0.95, 0.98};
		titlebarColor[] = {0.80, 0.82, 0.85, 1};
		accentColor[] = {0.15, 0.45, 0.75, 1};
		textColor[] = {0.10, 0.10, 0.10, 1};
	};

	class Olive : AE3_DesktopTheme
	{
		displayName = "$STR_AE3_Desktop_Theme_Olive";
		wallpaperColor[] = {0.10, 0.12, 0.08, 1};
		panelColor[] = {0.07, 0.08, 0.05, 0.95};
		windowColor[] = {0.13, 0.15, 0.11, 0.98};
		titlebarColor[] = {0.20, 0.24, 0.16, 1};
		accentColor[] = {0.55, 0.70, 0.30, 1};
		textColor[] = {0.90, 0.92, 0.85, 1};
	};
};

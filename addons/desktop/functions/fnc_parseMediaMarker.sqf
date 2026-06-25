#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Parses a media marker file content into its parts. A marker is created by
 * AE3_desktop_fnc_registerMedia and stored as a virtual filesystem file. The current format is
 * "AE3_MEDIA|<type>|<scope>|<web>|<source path>"; the legacy three-field form
 * "AE3_MEDIA|<type>|<source path>" is still understood (scope "auto", web off).
 *
 * Arguments:
 * 0: _content <ANY> - File content to inspect
 *
 * Return Value:
 * [_isMedia, _type, _scope, _web, _sourcePath] <ARRAY>
 *   _isMedia <BOOL>     - Whether the content is a media marker
 *   _type <STRING>      - "image" | "video" | "audio"
 *   _scope <STRING>     - "mod" | "mission" | "auto"
 *   _web <BOOL>         - Whether images should (experimentally) try the in-OS web viewer first
 *   _sourcePath <STRING>- Real path of the media file
 *
 * Example:
 * (["AE3_MEDIA|image|mission|0|media\images\x.jpg"] call AE3_desktop_fnc_parseMediaMarker) params ["_isMedia", "_type", "_scope", "_web", "_src"];
 *
 * Public: No
 */

params ["_content"];

if (!(_content isEqualType "") || {(_content select [0, 10]) isNotEqualTo "AE3_MEDIA|"}) exitWith
{
    [false, "", "auto", false, ""]
};

private _parts = _content splitString "|";
private _type = toLower (_parts param [1, ""]);
private _count = count _parts;

if (_count >= 5) exitWith
{
    private _scope = toLower (_parts param [2, "auto"]);
    if !(_scope in ["mod", "mission"]) then { _scope = "auto"; };
    private _web = (_parts param [3, "0"]) isEqualTo "1";
    // The path is the remainder so it survives a stray "|" in the source path.
    private _sourcePath = (_parts select [4]) joinString "|";
    [true, _type, _scope, _web, _sourcePath]
};

// Legacy "AE3_MEDIA|<type>|<source path>" marker.
private _sourcePath = (_parts select [2]) joinString "|";
[true, _type, "auto", false, _sourcePath]

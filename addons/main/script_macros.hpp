#include "\x\cba\addons\main\script_macros_common.hpp"

#define DFUNC(var1) TRIPLES(ADDON,fnc,var1)

// Filesystem symlink sentinel. A file whose string content begins with this prefix is a symbolic
// link; the remainder is the absolute target path. Mirrors the existing "AE3_LOCKED|" convention so
// symlinks ride through the normal [content, owner, perms] triple and the network filesystem sync
// untouched. Created via AE3_filesystem_fnc_symlink, parsed via AE3_filesystem_fnc_symlinkTarget.
#define AE3_SYMLINK_PREFIX "AE3_SYMLINK|"

// Base64 image marker sentinel. A file whose string content begins with this prefix stores a raw
// base64-encoded image inline instead of a real texture path: "AE3_MEDIA|image|b64|<mime>|<data>".
// Used when the source PNG cannot be shipped in the mission; the in-OS web viewer renders it as a
// data URL. Native RscPicture cannot render these, so the native viewer declines them.
#define AE3_MEDIA_B64_PREFIX "AE3_MEDIA|image|b64|"

// Maximum base64 payload length (characters) accepted for an inline picture file. ~2 MB of base64
// (~1.5 MB decoded). Enforced server-side in AE3_filesystem_fnc_device_addFile and pre-checked in the
// Zeus/Eden module handlers, since the payload rides the network sync and the CEF ExecJS transport.
#define AE3_MAX_PICTURE_B64 2097152

#ifdef DISABLE_COMPILE_CACHE
    #undef PREP
    #define PREP(fncName) DFUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #undef PREP
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

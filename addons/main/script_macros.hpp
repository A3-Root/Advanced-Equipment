#include "\x\cba\addons\main\script_macros_common.hpp"

#define DFUNC(var1) TRIPLES(ADDON,fnc,var1)

// Filesystem symlink sentinel. A file whose string content begins with this prefix is a symbolic
// link; the remainder is the absolute target path. Mirrors the existing "AE3_LOCKED|" convention so
// symlinks ride through the normal [content, owner, perms] triple and the network filesystem sync
// untouched. Created via AE3_filesystem_fnc_symlink, parsed via AE3_filesystem_fnc_symlinkTarget.
#define AE3_SYMLINK_PREFIX "AE3_SYMLINK|"

#ifdef DISABLE_COMPILE_CACHE
    #undef PREP
    #define PREP(fncName) DFUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #undef PREP
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

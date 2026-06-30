# Addon Components

Each component follows the common addon structure:

- `config.cpp`
- `script_component.hpp`
- `XEH_PREP.hpp`
- `XEH_preInit.sqf`
- optional `XEH_postInit.sqf`
- `functions/fnc_*.sqf`
- component config headers such as `CfgVehicles.hpp`

Functions are compiled through `PREP` entries in `XEH_PREP.hpp`. Do not call uncompiled file paths directly.

When adding new public behavior, document it in the relevant `wiki/Reference` page and add a mission-facing example if it changes workflow.

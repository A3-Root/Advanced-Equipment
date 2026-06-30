# API Overview

AE3 function names use component prefixes such as `AE3_desktop_fnc_*`, `AE3_armaos_fnc_*`, `AE3_filesystem_fnc_*`, `AE3_network_fnc_*`, `AE3_power_fnc_*`, `AE3_flashdrive_fnc_*`, and `AE3_interaction_fnc_*`.

## Locality

Prefer running setup scripts on the server:

```sqf
if (isServer) then {
    [_laptop, "admin", "password"] call AE3_armaos_fnc_computer_addUser;
};
```

Some desktop, power, and network APIs route client calls to the server, but server-side setup is the clearest pattern for mission initialization and JIP state.

## Public vs Internal

The repo compiles many functions for internal GUI, TUI, Zeus, and handler work. This reference documents functions that are useful to mission makers or addon developers. Internal callbacks are intentionally not listed as stable APIs unless they are needed to extend the framework.

## Common Target Forms

Many desktop intel APIs accept:

- A laptop object
- A laptop netId string
- An array of laptop objects
- `"all"` for initialized computers

Read each function page for exact target support.

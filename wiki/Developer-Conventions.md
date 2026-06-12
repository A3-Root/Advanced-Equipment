# Developer Conventions

Internal conventions for AE3 development. These apply to all new code; existing code is converted opportunistically when touched.

## CBA Macros

Every function file starts with:

```sqf
#include "..\script_component.hpp"
```

This provides the CBA macro set (`script_macros_common.hpp`) plus AE3's `PREP`/`DFUNC`. Use:

| Macro | Use | Expands to (example, COMPONENT=armaos) |
|-------|-----|----------------------------------------|
| `FUNC(x)` | Call a function in the same addon | `ae3_armaos_fnc_x` |
| `EFUNC(net,x)` | Call a function in another AE3 addon | `ae3_net_fnc_x` |
| `QFUNC(x)` / `QEFUNC(a,x)` | Quoted function name (for remoteExec, configs) | `"ae3_armaos_fnc_x"` |
| `GVAR(x)` | Internal global variable | `ae3_armaos_x` |
| `QGVAR(x)` | Quoted global var — also used as CBA event names | `"ae3_armaos_x"` |
| `QEGVAR(a,x)` | Quoted cross-addon global/event name | `"ae3_a_x"` |

Notes:
- SQF identifiers are case-insensitive: `FUNC(shell_stdout)` resolves to the same function as the public name `AE3_armaos_fnc_shell_stdout`.
- **Public API names stay `AE3_<addon>_fnc_<name>`** in documentation, function headers, and external-facing examples. Third-party mods (e.g. Root Cyberwarfare) call those names directly — never rename or remove them.
- Object variables keep the established `AE3_MixedCase` convention (`AE3_filesystem`, `AE3_computer_mutex`, ...). Do NOT introduce new ALL-CAPS globals — only `ROOT_ADVANCEDEQUIPMENT_*` is whitelisted by the linter.

## Logging (CBA style)

Use CBA logging macros instead of bare `diag_log` / `systemChat`:

```sqf
INFO_1("File already exists, skipping: %1",_exception);
WARNING_2("Failed to create user directory for '%1': %2",_username,_exception);
ERROR_2("Failed to create file %1: %2",_path,_exception);
```

RPT output format: `[ae3] (component) LEVEL: message`.

- `INFO_x` — expected/benign events worth recording.
- `WARNING_x` — recoverable problems.
- `ERROR_x` — failures (usually paired with a `throw` or early exit).
- `LOG_x` — verbose tracing; only compiled in with `DEBUG_MODE_FULL`.
- Player-facing debug chatter stays behind the runtime `AE3_DebugMode` CBA setting.

## Unicode safety (forceUnicode)

SQF string commands (`count`, `select [a,b]`, `find`, `splitString`, `reverse`, `insert`, `in`, `trim`, `regexFind/Match/Replace`, clipboard commands) count **bytes**, not characters. Any code that does character math on **user-generated** strings (terminal input, filenames, file content, usernames, messages) must wrap the affected section:

```sqf
forceUnicode 1;   // character mode
// ... count/select/splitString on user strings ...
forceUnicode -1;  // restore default
```

Applied in: terminal input editing (`fnc_terminal_removeCharFromInput`, `fnc_terminal_shiftInputBuffer`), line wrapping (`fnc_terminal_renderLine`), and the shell tokenizer. Follow the same pattern for new code paths that slice user strings.

## Filesystem permissions order

Permissions are stored and passed as `[[owner r, w, x], [everyone r, w, x]]` — standard `drwxrwx` order, matching the UI.

Numeric permission argument for `AE3_filesystem_fnc_hasPermission` / `fnc_getFile`:

| Value | Meaning |
|-------|---------|
| `0` | Read |
| `1` | Write |
| `2` | Execute |

Config form (`CfgFilesystemObjects`): `permissions[] = {{r,w,x},{r,w,x}};` with `1`/`0`.

## Async patterns

Banned in new code: `spawn` + `sleep` loops, `waitUntil` polling, `execVM` (lint-enforced).

| Need | Use |
|------|-----|
| Recurring tick | `CBA_fnc_addPerFrameHandler` (store handle, remove on cleanup) |
| One-shot delay | `CBA_fnc_waitAndExecute` |
| Wait for condition | `CBA_fnc_waitUntilAndExecute` (timeout variant available) |
| Cross-machine messaging | CBA events: `CBA_fnc_serverEvent`, `CBA_fnc_targetEvent`, `CBA_fnc_localEvent`, `CBA_fnc_globalEvent` |

`remoteExec` remains acceptable when targeting a specific object's owner or a player list; never use `remoteExec [..., 0, true]` (global + JIP-persistent) for state that the server can replay to late joiners.

Survivors that genuinely need the scheduled environment (e.g. the interactive shell process loop) carry an explanatory comment.

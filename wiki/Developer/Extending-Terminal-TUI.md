# Extending Terminal TUI

The terminal/TUI can be extended with mission-specific runtime commands or addon-wide config commands. Runtime commands are best for one mission or one laptop. Config commands are best for reusable addon features.

## Choosing an Extension Type

| Need | Use |
| --- | --- |
| One laptop gets one custom command in a mission | `AE3_armaos_fnc_computer_addCustomCommand`. |
| Every laptop of a scenario gets the same command set | Server setup script calling `computer_initWithCommands`. |
| Your addon contributes a reusable terminal command | `CfgOsFunctions` config class. |
| Optional hacking/security tool | `CfgSecurityCommands` or mission script installing selected tools. |
| Interactive terminal game | `CfgGames`, usually with `sshCompatible = 0`. |

## Runtime Command

Runtime commands are added to a laptop's filesystem and command link map.

```sqf
[
    _laptop,
    "scan",
    "/bin/scan",
    {
        params ["_computer", "_options", "_commandName"];
        [_computer, "No wireless anomalies detected."] call AE3_armaos_fnc_shell_stdout;
    },
    "Run site scan",
    "scan: prints local site scan"
] call AE3_armaos_fnc_computer_addCustomCommand;
```

Command code receives:

```sqf
params ["_computer", "_options", "_commandName"];
```

| Parameter | Meaning |
| --- | --- |
| `_computer` | Laptop the command executes against. During SSH this may be the remote target for command execution. |
| `_options` | Tokenized command arguments after the command name. |
| `_commandName` | Command name. Useful when one function backs several aliases. |

## Output

Use:

```sqf
[_computer, "Text"] call AE3_armaos_fnc_shell_stdout;
```

Do not use `hint` or `systemChat` as command output. Those go to the player UI, not the terminal buffer.

Formatted output:

```sqf
[
    _computer,
    [
        [["STATUS", "#8CE10B"], [" Relay online", "#FFFFFF"]],
        [["WARN", "#FFD966"], [" Battery low", "#FFFFFF"]]
    ]
] call AE3_armaos_fnc_shell_stdout;
```

## Parsing Arguments

For simple commands, read `_options` directly:

```sqf
private _mode = _options param [0, "status"];
```

For commands with flags, use `AE3_armaos_fnc_shell_getOpts`.

```sqf
private _settings = [
    "scan",
    [
        ["_fast", "-f", "--fast", "bool", false, false, "Run a short scan"],
        ["_target", "-t", "--target", "string", "", true, "Target name"]
    ],
    "scan --target NAME [-f]"
];

private _ae3OptsSuccess = false;
private _fast = false;
private _target = "";
[] params ([_computer, _options, _settings] call AE3_armaos_fnc_shell_getOpts);
if (!_ae3OptsSuccess) exitWith {};

[_computer, format ["Scanning %1. Fast: %2", _target, _fast]] call AE3_armaos_fnc_shell_stdout;
```

The parser prints help and returns unsuccessful state when the user passes `-h` or `--help`.

## Server-Side State Changes

Commands run in the terminal context. If a command changes mission state, route that change to the server.

Client command:

```sqf
[
    _laptop,
    "door",
    "/bin/door",
    {
        params ["_computer", "_options", "_commandName"];

        private _open = (_options param [0, "status"]) isEqualTo "open";
        ["myMission_setDoorOpen", [_open]] call CBA_fnc_serverEvent;
        [_computer, "Door request sent."] call AE3_armaos_fnc_shell_stdout;
    },
    "Control door",
    "door open"
] call AE3_armaos_fnc_computer_addCustomCommand;
```

Server handler:

```sqf
if (isServer) then {
    ["myMission_setDoorOpen", {
        params ["_open"];
        missionNamespace setVariable ["myMission_doorOpen", _open, true];
    }] call CBA_fnc_addEventHandler;
};
```

## Config Command

Addon-wide commands use config:

```cpp
class CfgOsFunctions
{
    class scan
    {
        path = "/bin/scan";
        description = "Runs a local scan.";
        man = "scan [-f]: runs a local scan.";
        code = "call myMod_fnc_os_scan";
        sshCompatible = 1;
    };
};
```

Function:

```sqf
#include "..\script_component.hpp"
/*
 * Description: Runs the scan terminal command.
 */

params ["_computer", "_options"];

[_computer, "Scan complete."] call AE3_armaos_fnc_shell_stdout;
```

Install selected command:

```sqf
[_laptop, ["scan"], false, false, []] call AE3_armaos_fnc_computer_initWithCommands;
```

If your command config lives outside AE3, make sure your addon loads after the component that reads the command config.

## Filesystem Commands

Commands are stored as files. Runtime commands create a file at `_commandPath`, then create a command link from `_commandName` to that path.

Useful conventions:

| Path | Use |
| --- | --- |
| `/bin/<command>` | Normal user command. |
| `/sbin/<command>` | System/network/power command. |
| `/games/<command>` | Game/interactive command. |
| `/usr/bin/<command>` | Addon or userland utility command. |

Command file permissions must allow execute for the user who will run it.

## SSH Compatibility

SSH sessions execute commands against the remote computer while output is redirected to the local terminal. Commands that require local display state or nested SSH should be blocked over SSH.

Config commands can set:

```cpp
sshCompatible = 0;
```

Use this for:

- Interactive games.
- Commands that open GUI dialogs.
- Commands that depend on local player controls.
- Commands that start another SSH session.

Runtime custom commands do not currently expose a config property for SSH compatibility, so design them to be safe over SSH or avoid installing them on remote-admin laptops.

## Command Quality Checklist

- Validate arguments and print a useful error.
- Use `shell_stdout` for output.
- Do not assume a GUI desktop exists.
- Do not directly mutate terminal buffers.
- Route durable state changes to the server.
- Avoid heavy loops inside command execution.
- Handle missing files, missing network, and powered-off devices gracefully.
- Add `man` text for commands players are expected to discover.
- Document addon-wide commands in [Terminal Commands](../Reference/Terminal-Commands.md).

## Related Pages

- [ArmaOS API](../Reference/ArmaOS-API.md)
- [Terminal Commands](../Reference/Terminal-Commands.md)
- [Filesystem API](../Reference/Filesystem-API.md)
- [Locality and Multiplayer](Locality-and-Multiplayer.md)

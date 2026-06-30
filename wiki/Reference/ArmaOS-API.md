# ArmaOS API

ArmaOS controls users, terminal commands, command links, command execution, terminal output, games, and security commands.

## User and Command Setup

| Function | Purpose |
| --- | --- |
| `AE3_armaos_fnc_computer_addUser` | Add a user and create `/home/<user>`. |
| `AE3_armaos_fnc_computer_addSecurityCommands` | Add `crypto` and/or `crack`. |
| `AE3_armaos_fnc_computer_addGames` | Add supported games, currently Snake. |
| `AE3_armaos_fnc_computer_addCustomCommand` | Add a runtime command to one laptop. |
| `AE3_armaos_fnc_computer_initWithCommands` | Initialize a laptop with selected base, security, game, and custom commands. |
| `AE3_armaos_fnc_computer_addCalendarEvent` | Add a terminal-side calendar event. |
| `AE3_armaos_fnc_computer_removeCalendarEvent` | Remove a terminal-side calendar event. |

```sqf
[_laptop, "admin", "swordfish"] call AE3_armaos_fnc_computer_addUser;
[_laptop, true, true] call AE3_armaos_fnc_computer_addSecurityCommands;
[_laptop, true] call AE3_armaos_fnc_computer_addGames;
```

## Custom Command

Command code receives `[_computer, _options, _commandName]`.

```sqf
[_laptop, "door", "/bin/door", {
    params ["_computer", "_options", "_commandName"];
    [_computer, "Door relay armed"] call AE3_armaos_fnc_shell_stdout;
}, "Control door relay", "door: prints relay status"] call AE3_armaos_fnc_computer_addCustomCommand;
```

## Execute Input

| Function | Purpose |
| --- | --- |
| `AE3_armaos_fnc_shell_process` | Process a command string on a laptop. |
| `AE3_armaos_fnc_shell_stdout` | Print terminal output from command code. |
| `AE3_armaos_fnc_shell_stdin` | Read stdin-style terminal input when used by command logic. |

```sqf
[_laptop, "ls /var/log"] call AE3_armaos_fnc_shell_process;
```

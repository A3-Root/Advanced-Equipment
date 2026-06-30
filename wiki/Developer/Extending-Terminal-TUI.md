# Extending Terminal TUI

## Runtime Command

```sqf
[_laptop, "scan", "/bin/scan", {
    params ["_computer", "_options", "_commandName"];
    [_computer, "No wireless anomalies detected."] call AE3_armaos_fnc_shell_stdout;
}, "Run site scan", "scan: prints local site scan"] call AE3_armaos_fnc_computer_addCustomCommand;
```

## Config Command

Commands in `CfgOsFunctions` define:

- `path`
- `description`
- `man`
- `code`

Use config commands for addon-wide commands and runtime commands for mission-specific laptops.

## Command Behavior

Keep command output concise. Use `AE3_armaos_fnc_shell_stdout` for terminal output and avoid directly editing terminal internals.

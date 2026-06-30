# Terminal TUI

The terminal is AE3's command-line laptop interface. It runs ArmaOS commands from the laptop filesystem and command link registry.

## Common Commands

```text
help
man ls
ls /home/admin
cd /var/log
cat browser_history
ip
ping 10.0.0.4
ssh admin@10.0.0.4
msg 10.0.0.5 "open the gate"
lsusb
mount usb0
umount usb0
unlock /home/admin/locked.txt
```

## Command Sources

Base commands are configured in `CfgOsFunctions`. Security commands such as `crypto` and `crack` are configured in `CfgSecurityCommands`. Games are configured in `CfgGames`.

Mission makers can add commands at runtime:

```sqf
[_laptop, "status", "/bin/status", {
    params ["_computer", "_options", "_commandName"];
    [_computer, "Generator online"] call AE3_armaos_fnc_shell_stdout;
}, "Print site status", "status: prints mission status"] call AE3_armaos_fnc_computer_addCustomCommand;
```

## GUI Relationship

The desktop includes a Terminal app, but a laptop can also expose the classic terminal directly. Configure `cli`, `gui`, or `both` depending on the intended player experience.

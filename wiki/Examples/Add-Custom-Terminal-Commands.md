# Add Custom Terminal Commands

Custom terminal commands are an advanced workflow. This recipe explains what is possible in Eden, Zeus, and API/addon work.

For most missions, do not create a custom command first. Use built-in commands, files, browser pages, mail, media, locked files, and Zeus live clues when they can represent the gameplay.

## No-Code Alternatives

Use these before writing code:

| Desired behavior | Easier alternative |
| --- | --- |
| Player reads information | Add File, Email, Webpage, Calendar Event, or Media. |
| Player discovers a command result | Put the output in a hidden/locked file. |
| Player needs a password | Use Locked File and place the password clue elsewhere. |
| Player must inspect network | Use built-in `ip`, `ping`, `ssh`, or `msg`. |
| Player must inspect USB | Use built-in `lsusb`, `mount`, `umount`, `cat`. |
| Live operator gives result | Zeus adds a file/email/webpage during play. |

## Eden Editor Workflow

There is no pure no-code Eden module for defining a brand-new terminal command. Eden can install built-in optional commands through laptop attributes:

1. Place/select the laptop.
2. Open laptop attributes.
3. Enable optional command/game checkboxes:
   - Crypto.
   - Crack.
   - Snake.
4. Use Add File/Add Directory modules to create supporting files.
5. Preview and verify `help` lists the intended commands.

For a truly custom command in Eden, use the API workflow from `initServer.sqf`, an object init that runs safely on the server, or an addon.

## Zeus Workflow

There is no safe live Zeus dialog for creating arbitrary executable terminal commands. During a live mission, use one of these instead:

- Add a file containing the command result.
- Add an email or webpage clue.
- Add a locked file that players unlock with existing tools.
- Roleplay the result through Zeus.
- Use API/debug tooling only if the mission framework already provides a vetted function.

Avoid creating arbitrary code from Zeus text fields during live play.

## API Workflow

Run this on the server after the laptop filesystem exists.

```sqf
if (isServer) then {
    [
        _laptop,
        "relay",
        "/bin/relay",
        {
            params ["_computer", "_options", "_commandName"];

            private _mode = _options param [0, "status"];
            switch (_mode) do {
                case "open": {
                    missionNamespace setVariable ["myMission_relayOpen", true, true];
                    [_computer, "Relay opened."] call AE3_armaos_fnc_shell_stdout;
                };
                case "close": {
                    missionNamespace setVariable ["myMission_relayOpen", false, true];
                    [_computer, "Relay closed."] call AE3_armaos_fnc_shell_stdout;
                };
                default {
                    private _state = ["closed", "open"] select (missionNamespace getVariable ["myMission_relayOpen", false]);
                    [_computer, format ["Relay is %1.", _state]] call AE3_armaos_fnc_shell_stdout;
                };
            };
        },
        "Control relay",
        "relay [status|open|close]"
    ] call AE3_armaos_fnc_computer_addCustomCommand;
};
```

## Addon Config Workflow

For reusable commands, define a config command and a function.

```cpp
class CfgOsFunctions
{
    class relay
    {
        path = "/bin/relay";
        description = "Shows relay status.";
        man = "relay [status|open|close]";
        code = "call myMod_fnc_os_relay";
        sshCompatible = 1;
    };
};
```

Then install it on selected laptops:

```sqf
[_laptop, ["relay"], false, false, []] call AE3_armaos_fnc_computer_initWithCommands;
```

## Testing

1. Log into the laptop.
2. Run `help`.
3. Confirm the command appears.
4. Run the command with no arguments.
5. Run each expected argument.
6. Test as the intended user and as root/admin.
7. Test over SSH if the command is meant to be SSH-compatible.
8. Test on dedicated server if the command changes mission state.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| `help` does not show the command | Command link was not installed on that laptop. |
| Command runs but prints nothing | Use `AE3_armaos_fnc_shell_stdout`. |
| Command changes state only locally | Route durable state changes to the server. |
| Command fails over SSH | It may depend on local UI or be marked/treated as not SSH-compatible. |
| Mission can be solved with a file | Use a file instead of custom code. |

## Related Pages

- [ArmaOS API](../Reference/ArmaOS-API.md)
- [Terminal Commands](../Reference/Terminal-Commands.md)
- [Extending Terminal TUI](../Developer/Extending-Terminal-TUI.md)

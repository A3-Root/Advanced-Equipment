# Terminal TUI

The Terminal TUI is AE3's command-line computer interface. It is intended for missions where players inspect files, use network tools, mount USB drives, unlock files, or operate a laptop through typed commands.

## Common Player Commands

The exact command list depends on the laptop. Players should start with:

- `help`: list available commands.
- `man`: show manual text for a command.
- `ls`: list files and folders.
- `cd`: change folder.
- `cat`: read a file.
- `ip`: show network information.
- `ping`: check whether another address is reachable.
- `ssh`: connect to a remote laptop.
- `msg`: send a network message.
- `lsusb`: list connected USB interfaces.
- `mount`: mount a flash drive.
- `umount`: unmount a flash drive.
- `unlock`: open a passworded file.

Not every laptop has every command. Mission makers can choose command sets.

## Good Terminal Mission Content

Use terminal gameplay for:

- Log inspection.
- Finding hidden files.
- Network discovery.
- SSH chains.
- Flash drive handling.
- Passworded or encrypted file puzzles.
- Minimalist terminals where players must infer what to do.

Avoid placing all clues in GUI-only apps if the laptop is configured as CLI-only.

## Mission-Maker Setup

In 3DEN:

1. Set laptop Interface Mode to CLI or Both.
2. Add a user.
3. Add folders and files.
4. Add security commands or custom command setup if the laptop attributes/modules expose them.
5. Add network and flash drive gameplay only if players have enough clues to use it.
6. Preview and test with the same interface players will use.

Script command creation belongs in [ArmaOS API](../Reference/ArmaOS-API.md) and [Extending Terminal TUI](../Developer/Extending-Terminal-TUI.md).

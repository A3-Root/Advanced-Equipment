# Configure GUI vs TUI Access

This recipe controls which laptop interface players can use: graphical desktop (GUI), terminal command line (TUI/CLI), or both. It includes Eden Editor, Zeus, and API workflows.

## Interface Choices

| Mode | Use when |
| --- | --- |
| GUI | Players should use Files, Browser, Mail, Calendar, media, CCTV, or desktop apps. |
| CLI/TUI | Players should use terminal commands, SSH, ping, mount, cat, grep, unlock, or command-line puzzles. |
| Both | Players should have a complete computer experience. |

## Eden Editor Workflow

Use object attributes before mission start.

1. Place or select an AE3 laptop.
2. Double-click the laptop.
3. Find the AE3 laptop attributes.
4. Set `Interface Mode`:
   - `GUI` for desktop only.
   - `CLI` for terminal only.
   - `Both` for both ACE actions.
   - `Default` to use the mission/CBA default.
5. Set software toggles if needed:
   - Crypto.
   - Crack.
   - Snake.
6. Preview the mission.
7. Confirm the expected ACE actions appear.

Eden is the best place to set the default interface for planned mission laptops.

## Copy-Paste Role Sets

Use these patterns when you want the interface model to define the mission structure:

| Pattern | Result |
| --- | --- |
| `GUI` for intel officers, `CLI` for technicians | Forces different roles to use different clue surfaces. |
| `Both` on a primary laptop, `CLI` on backups | Lets one machine handle full desktop clues while another becomes a terminal fallback. |
| `GUI` gated by a keycard or custom condition | Creates a locked workspace players must earn. |
| `Default` on disposable laptops | Lets mission settings decide the final mode. |

If the mission also uses browser pages or media, pair GUI access with the browser sample pages so the desktop side has something meaningful to show.

## Zeus Workflow

Use this during live play when access needs to change.

1. Open Zeus.
2. Select the target laptop or place the Zeus interface access module on it.
3. Use `AE3: Interface Access` if available.
4. Choose which interface is affected: GUI, CLI, or both.
5. Choose who should have access, such as side/player-based access depending on the dialog.
6. Apply the change.
7. Ask players to retry the ACE interaction if they already had the interaction menu open.

Live-use examples:

- Unlock GUI access after players find a keycard.
- Disable terminal access for non-technical roles.
- Give BLUFOR the desktop while OPFOR can only use a guest terminal account.
- Restore access after a scripted outage.

## API Workflow

Set interface mode:

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
};
```

Valid modes:

```sqf
"cli"
"gui"
"both"
```

Restrict GUI to a side:

```sqf
if (isServer) then {
    [_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
};
```

Restrict CLI to one Steam UID:

```sqf
if (isServer) then {
    [_laptop, "cli", ["76561198000000000"]] call AE3_desktop_fnc_setInterfaceAccess;
};
```

Use a custom condition:

```sqf
if (isServer) then {
    [_laptop, "gui", {
        params ["_laptop", "_player"];
        _player getVariable ["myMission_hasLaptopKeycard", false]
    }] call AE3_desktop_fnc_setInterfaceAccess;
};
```

Check access:

```sqf
private _canUseGui = [_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface;
```

## Testing

1. Test as a player who should have access.
2. Test as a player who should not have access.
3. Test after JIP.
4. Test with the laptop powered off and back on.
5. Test if another player is already using the laptop.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| GUI action does not appear | Interface mode may be CLI/default, or access condition blocks the player. |
| Terminal action does not appear | Interface mode may be GUI/default, or access condition blocks the player. |
| Zeus changes seem ignored | Players may need to close/reopen ACE interaction menu. |
| API condition works on host but not dedicated | Ensure condition code and variables exist on all machines that evaluate access. |
| Players can open interface but cannot log in | Interface access and laptop user credentials are separate systems. |

## Related Pages

- [Laptops and Interfaces](../Systems/Laptops-and-Interfaces.md)
- [Desktop API](../Reference/Desktop-API.md)
- [Eden Attributes](../Reference/Eden-Attributes.md)
- [Examples Library](README.md)

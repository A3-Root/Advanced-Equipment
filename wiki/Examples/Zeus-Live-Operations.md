# Zeus Live Operations

This recipe covers live curator actions during an active mission. It focuses on what Zeus can do directly, how that differs from Eden setup, and when API support is the cleaner path.

## What Zeus Is Best At

Zeus is best for:

- Adding emergency clues.
- Repairing a setup mistake.
- Giving players new information after an event.
- Powering, crashing, reconnecting, or replacing devices.
- Adding users, files, folders, calendar events, or live intel.
- Adjusting access during roleplay.

Zeus is not ideal for:

- Large planned laptop builds.
- Complex filesystem trees.
- Arbitrary executable code.
- New desktop app definitions.
- Large media pipelines.

Use Eden or API setup for planned complexity.

## Copy-Paste Live Bundle

Use this when you need a live emergency intel chain without rebuilding the whole mission:

```sqf
if (isServer) then {
    [_laptop, "admin", "orchard"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "handler@lan", "New tasking", "Check intel.root/live.", "admin@lan"] call AE3_desktop_fnc_addEmail;
    ["intel.root/live", "Live Update", "Move to fallback site Bravo.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/live", "03:12"] call AE3_desktop_fnc_addHistoryEntry;
};
```

If the live clue needs to look like a full page rather than a short intel card, use the browser sample pages as the starting point and register the live URL on top of them.

## Add a Live Clue

### Zeus Workflow

1. Identify the target laptop.
2. Check whether players can access it:
   - Power state.
   - GUI/TUI interface mode.
   - Login credentials.
3. Add a user if players need credentials.
4. Add the clue:
   - `AE3: Add File` for plain documents.
   - `AE3: Add Directory` for folder structure.
   - `AE3: Add Calendar Event` for date/location intel.
   - `AE3: Add Intel` for email, webpage, browser history, media, or locked content where exposed by the dialog.
5. If the clue is a webpage, also add browser history or another clue pointing to the URL.
6. Tell players in-world that new information may exist.

### API Equivalent

```sqf
if (isServer) then {
    [_laptop, "admin", "orchard"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "handler@lan", "New tasking", "Check intel.root/live.", "admin@lan"] call AE3_desktop_fnc_addEmail;
    ["intel.root/live", "Live Update", "Move to fallback site Bravo.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/live", "03:12"] call AE3_desktop_fnc_addHistoryEntry;
};
```

## Fix a Broken Laptop During Play

### Zeus Workflow

1. Check power:
   - Is the laptop turned on?
   - Is its power source running?
   - Is the internal/external battery empty?
2. Check use state:
   - Is another player currently using it?
   - Is the lid/open state blocking an interaction?
3. Check interface:
   - GUI, CLI, Both, or Default.
   - Access restrictions by side/player.
4. Check credentials:
   - Add a temporary user if needed.
5. Check content:
   - Use filesystem browser or Add File/Add Intel tools.
6. Apply the smallest fix that preserves the mission.

### API Equivalent

```sqf
if (isServer) then {
    [_generator] call AE3_power_fnc_turnOnDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "guest", "guest"] call AE3_armaos_fnc_computer_addUser;
};
```

## Run a Sabotage Moment

### Zeus Workflow

1. Wait until players have enough context.
2. Crash or power off the target device.
3. Provide a recovery path:
   - Power-cycle the laptop.
   - Find another device.
   - Restore from a saved state.
   - Repair power/network connection.
   - Receive a follow-up clue from Zeus.
4. Avoid permanent failure unless the mission has a fallback.

### API Equivalent

```sqf
[_laptop] call AE3_power_fnc_crashDevice;
```

Recover later:

```sqf
if (isServer) then {
    [_laptop] call AE3_power_fnc_turnOffDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;
};
```

## Change GUI/TUI Access Live

### Zeus Workflow

1. Use `AE3: Interface Access` on the target laptop if available.
2. Choose GUI, CLI, or both.
3. Restrict by side/player depending on the dialog options.
4. Apply.
5. Ask players to retry their ACE interaction.

### API Equivalent

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
    [_laptop, "cli", { true }] call AE3_desktop_fnc_setInterfaceAccess;
};
```

## Repair a Network Live

### Zeus Workflow

1. Check whether the router is powered.
2. Check whether the laptop is powered.
3. Use Zeus connection tools to reconnect laptop to router.
4. Check router attributes such as gateway, range, password, and external access.
5. Give players a reason to try `ip`, `ping`, `ssh`, or Browser/Mail again.

### API Equivalent

```sqf
if (isServer) then {
    [_router, "Emergency Net", 150, "", "10.50.0.1", true, ""] call AE3_network_fnc_applyRouterConfig;
    [_laptop, _router] call AE3_network_fnc_createNetworkConnection;
    [_router] call AE3_power_fnc_turnOnDevice;
};
```

## Eden Equivalent

For anything you know before mission start, prefer Eden:

- Place laptops, routers, and power devices.
- Configure object attributes.
- Sync Add User/Add File/Add Directory/Add Webpage/Add Email modules.
- Use custom Eden connections for power/network.
- Preview and test before the session.

Zeus should be the live operations tool, not the substitute for planned setup.

## Good Live Operation Rules

- Add new evidence rather than rewriting old evidence where possible.
- Do not make players guess passwords with no clues.
- Match the clue to the interface players are actually using.
- Keep live-added content short and readable.
- Avoid fixing problems invisibly if players are actively investigating them.
- Preserve player agency: if they broke the power, let power be part of the recovery.
- Use API/server execution for complex state changes rather than manual local edits.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| Zeus clue appears on wrong laptop | Confirm target/sync before applying. |
| Players cannot see new content | Check power, login, interface, app refresh, and permissions. |
| Live power change breaks the mission | Provide a recovery path or second laptop. |
| Network repair works only briefly | Router or laptop power may still be failing. |
| Too much live text | Use one file/email/page with clear next action. |

## Related Pages

- [Zeus Guide](../Zeus-Guide.md)
- [Zeus API](../Reference/Zeus-API.md)
- [Debugging](../Developer/Debugging.md)
- [Browser Sample Pages](Browser-Sample-Pages.md)
- [Examples Library](README.md)

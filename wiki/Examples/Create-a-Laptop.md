# Create a Laptop

This recipe creates a basic AE3 laptop with an interface, a login account, and one clue. It includes Eden Editor, Zeus, and API workflows.

## What You Are Building

A useful first laptop normally needs:

1. A placed AE3 laptop object.
2. Power or enough internal battery.
3. GUI, CLI, or Both interface mode.
4. At least one user account.
5. At least one clue: file, email, webpage, browser history, media, calendar event, or locked file.

## Eden Editor Workflow

Use this for planned mission content.

1. Place an AE3 laptop from the AE3 asset category.
2. Double-click the laptop.
3. Set `Interface Mode` to `GUI`, `CLI`, or `Both`.
4. Enable `Powered On At Start` if the laptop should be ready immediately.
5. Place `AE3: Add User`.
6. Double-click the module.
7. Enter username `admin` and a password players can discover.
8. Sync the Add User module to the laptop.
9. Add one clue:
   - `AE3: Add File` for a text document.
   - `AE3: Add Email` for a message.
   - `AE3: Add Webpage` for browser content.
   - `AE3: Add Browser History` for a browsing trail.
   - `AE3: Add Calendar Event` for a date/location clue.
   - `AE3: Add Media` for image/audio/video.
   - `AE3: Add Passworded File` for locked content.
10. Sync the clue module to the same laptop.
11. Preview.
12. Open the laptop through ACE and verify the account and clue.

## Zeus Workflow

Use this for live mission changes or emergency content.

1. Open Zeus.
2. Place an AE3 laptop if one does not already exist.
3. Power it or connect it to a power source if the mission requires power.
4. Use `AE3: Add User` to add a login account.
5. Use the available Zeus content module:
   - `AE3: Add File` or `AE3: Add Directory` for filesystem content.
   - `AE3: Add Calendar Event` for calendar intel.
   - `AE3: Add Intel` for email, webpage, browser history, media, or similar intel types.
6. Apply the module to the laptop.
7. If players are already using the laptop, ask them to reopen the relevant app or folder if needed.

## API Workflow

Run setup on the server.

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "admin", "swordfish"] call AE3_armaos_fnc_computer_addUser;

    private _fs = _laptop getVariable "AE3_filesystem";
    [[], _fs, "/home/admin/Desktop/brief.txt", "Check intel.root/depot.", "root", "admin"] call AE3_filesystem_fnc_ensureFile;
    _laptop setVariable ["AE3_filesystem", _fs, true];

    ["intel.root/depot", "Depot Page", "Crates moved at 0415.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
};
```

Add power and network:

```sqf
if (isServer) then {
    [_laptop, _generator] call AE3_power_fnc_createPowerConnection;
    [_generator] call AE3_power_fnc_turnOnDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;

    [_laptop, _router] call AE3_network_fnc_createNetworkConnection;
};
```

## Testing Checklist

- Laptop can be interacted with.
- Correct interface action appears.
- Laptop is powered or can be powered.
- Username and password work.
- GUI users can see their Desktop and apps.
- Terminal users can run `help`, `ls`, and `cat` if those commands are installed.
- The clue appears in the expected place.
- Another user/side cannot access content that should be restricted.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| Laptop placed but unusable | Check power and interface mode. |
| Login fails | Add/sync/apply a user account. |
| File exists but GUI user cannot find it | Put it on `/home/<user>/Desktop` or provide a path clue. |
| Browser page exists but history is empty | Add a Browser History entry separately. |
| Zeus-created clue does not show | Reopen the relevant GUI app or verify module targeted the laptop. |

## Related Pages

- [Getting Started](../Getting-Started.md)
- [Eden Editor Guide](../Eden-Editor-Guide.md)
- [Zeus Guide](../Zeus-Guide.md)

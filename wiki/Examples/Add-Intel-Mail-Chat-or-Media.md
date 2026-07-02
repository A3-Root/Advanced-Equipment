# Add Intel, Mail, Chat, or Media

This recipe helps you add richer laptop clues: email, calendar entries, browser content, media, locked files, and live intel. It includes Eden Editor, Zeus, and API workflows.

## Choose the Right Intel Type

| Type | Best for |
| --- | --- |
| Email | Orders, personal messages, sender/recipient clues, time-sensitive communications. |
| Calendar | Meetings, deadlines, handoffs, delivery windows, location/date clues. |
| Browser page | Short web-style intel and navigable clue chains. |
| Browser history | Showing what a previous user looked at. |
| Media | Images, audio, and video evidence. |
| Locked file | Password-gated documents or evidence. |
| Chat/message | Live or networked communication behavior; use system/API support where available. |

## Eden Editor Workflow

Use this before mission start.

### Email

1. Place an AE3 laptop with GUI or Both interface mode.
2. Place `AE3: Add Email`.
3. Open module attributes.
4. Fill:
   - `From`: for example `handler@lan`.
   - `To`: for example `admin@lan`.
   - `Subject`: for example `Before dawn`.
   - `Body`: message content.
   - `Received`: optional `HH:MM`.
   - `Create sender address` / `Create recipient address`: enable if the address should exist in the address book.
5. Sync the module to the laptop.

### Calendar Event

1. Place `AE3: Add Calendar Event`.
2. Enter date as `YYYY-MM-DD`.
3. Enter title, location, and details.
4. Sync to the laptop.

### Media

1. Put the media file in the mission folder or ship it in a loaded mod.
2. Place `AE3: Add Media`.
3. Set:
   - `Source path`: for example `media\images\safehouse.jpg`.
   - `Media type`: Image, Video, or Audio.
   - `Laptop path`: for example `/home/admin/Desktop/safehouse.jpg`.
   - `Path type`: Mission file or Mod path.
   - `Try Web View`: leave disabled unless testing the experimental web viewer.
4. Sync to the laptop.

### Locked File

1. Place `AE3: Add Passworded File`.
2. Set laptop path, for example `/home/admin/Desktop/locked.txt`.
3. Set password.
4. Set protected content.
5. Set owner.
6. Sync to the laptop.

### Browser Content

Use `AE3: Add Webpage` and `AE3: Add Browser History`. See [Add Webpages and Browser History](Add-Webpages-and-Browser-History.md).

## Copy-Paste Intel Bundle

Use this when you want a full clue chain in one mission seed:

```sqf
if (isServer) then {
    [_laptop, "handler@lan", "Before dawn", "Open the depot page, then check the gallery and the social feed.", "admin@lan", "01:58", true, true] call AE3_desktop_fnc_addEmail;
    [_laptop, "2026-06-30", "Courier handoff", "Pier 4", "Encrypted drive transfer."] call AE3_armaos_fnc_computer_addCalendarEvent;

    ["intel.root/depot", "Depot Page", "Crates moved to safehouse Bravo.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;

    ["media\\images\\safehouse.jpg", "image", "/home/admin/Desktop/safehouse.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;
    [_laptop, "/home/admin/Desktop/archive.txt", "orchard", "Fallback route: Blue tunnel.", "admin"] call AE3_desktop_fnc_addLockedFile;
};
```

Use the browser sample pages when you want the webpage itself to be a richer landing page rather than a short intel card.

## Zeus Workflow

Use this during live play.

1. Open Zeus.
2. Target the laptop.
3. Use `AE3: Add Intel` for live intel types such as email, webpage, browser history, media, or locked-file style content when exposed by the dialog.
4. Use `AE3: Add Calendar Event` for calendar entries.
5. Use `AE3: Add File` for plain documents.
6. Apply the module/dialog.
7. Tell players through roleplay, task update, radio, or another clue that new laptop intel may exist.

Zeus does not need to mirror Eden's exact module list. Some Eden modules are editor-only entries, while Zeus uses a live Add Intel dialog for the same category of content.

## API Workflow

Run setup on the server.

### Email

```sqf
if (isServer) then {
    [
        _laptop,
        "handler@lan",
        "Before dawn",
        "Check intel.root/depot before 0415.",
        "admin@lan",
        "01:58",
        true,
        true
    ] call AE3_desktop_fnc_addEmail;
};
```

### Calendar

```sqf
if (isServer) then {
    [_laptop, "2026-06-30", "Courier handoff", "Pier 4", "Encrypted drive transfer."] call AE3_armaos_fnc_computer_addCalendarEvent;
};
```

### Media

```sqf
if (isServer) then {
    ["media\images\safehouse.jpg", "image", "/home/admin/Desktop/safehouse.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;
};
```

### Locked File

```sqf
if (isServer) then {
    [_laptop, "/home/admin/Desktop/archive.txt", "orchard", "Archive route: Blue tunnel.", "admin"] call AE3_desktop_fnc_addLockedFile;
};
```

### Browser Trail

```sqf
if (isServer) then {
    ["intel.root/depot", "Depot Page", "Crates A-17 and A-18 are missing.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
};
```

## Full Combined Intel Example

```sqf
if (isServer) then {
    [_laptop, "admin", "orchard"] call AE3_armaos_fnc_computer_addUser;

    [_laptop, "handler@lan", "Before dawn", "Open the depot page, then check the safehouse photo.", "admin@lan", "01:58"] call AE3_desktop_fnc_addEmail;

    ["intel.root/depot", "Depot Page", "Crates moved to safehouse Bravo.", _laptop] call AE3_desktop_fnc_registerWebpage;
    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;

    ["media\images\safehouse.jpg", "image", "/home/admin/Desktop/safehouse.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;
    [_laptop, "/home/admin/Desktop/archive.txt", "orchard", "Fallback route: Blue tunnel.", "admin"] call AE3_desktop_fnc_addLockedFile;
};
```

## Testing

GUI:

1. Log in as the target user.
2. Open Mail and check the email.
3. Open Browser and check history/page.
4. Open Files and inspect media or locked file.
5. Open Calendar and verify date entries.

Terminal:

1. Use `cat` to inspect readable filesystem content.
2. Use `unlock` if a locked file is part of the puzzle.
3. Use `find` or `grep` if players are expected to search.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| Media does not open | Check source path, path type, media type, and file availability. |
| Email missing | Confirm target laptop and logged-in user context. |
| Browser clue incomplete | Register both page and history if players should open it. |
| Locked file has no clue | Put the password hint somewhere discoverable. |
| Zeus live content unnoticed | Add an in-world reason to re-check the laptop. |

## Related Pages

- [Intel, Mail, Chat, and Media](../Systems/Intel-Mail-Chat-Media.md)
- [Desktop API](../Reference/Desktop-API.md)
- [Browser API](../Reference/Browser-API.md)
- [Browser Sample Pages](Browser-Sample-Pages.md)
- [Examples Library](README.md)

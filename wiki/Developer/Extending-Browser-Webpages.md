# Extending Browser Webpages

AE3's Browser is an in-game clue and intel system. It is not a real internet browser. Developers register fictional webpages and optional browser history entries, then players discover them through the GUI Browser, files, emails, terminal commands, or other mission clues.

## When to Use Browser Pages

Use Browser pages for:

- Intranet-style mission intel.
- Search-history clues.
- A page linked from an email.
- A page containing a password hint.
- A directory/index that points players to other pages.
- A fake corporate, military, or insurgent web portal.

Use normal filesystem files instead when the content should look like a downloaded document, note, log, or report.

## Registering a Page

```sqf
[
    "intel.root/convoys",
    "Convoy Board",
    "North convoy: 0415" + endl + "Escort: MRAP x2",
    _laptop
] call AE3_desktop_fnc_registerWebpage;
```

Target options:

| Target | Meaning |
| --- | --- |
| `_laptop` | Page exists for one laptop. |
| `[_laptopA, _laptopB]` | Page exists for selected laptops. |
| `"all"` | Page is available to all initialized computers. |

Use targeted pages when the laptop itself is the clue. Use `"all"` for public intranet pages that every machine should resolve.

## Page Content Style

Build readable plain text:

```sqf
private _content = [
    "OPERATIONS INDEX",
    "",
    "convoys - convoy movements",
    "relay - radio relay instructions",
    "archive - old mission notes"
] joinString endl;

["intel.root/home", "Operations Index", _content, _laptop] call AE3_desktop_fnc_registerWebpage;
```

Avoid making long walls of text. Use pages as navigable clues:

- One index page.
- A few detail pages.
- Browser history entries that imply what mattered to the previous user.
- Emails/files that point at exact URLs.

## Browser History

```sqf
[_laptop, "intel.root/home", "02:03"] call AE3_desktop_fnc_addHistoryEntry;
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
```

History is stored at:

```text
/var/log/browser_history
```

Players can find it through:

- Browser UI history.
- Files app.
- Terminal `cat /var/log/browser_history`.
- Custom commands that read the file.

## Full Intel Trail Example

```sqf
if (isServer) then {
    private _home = [
        "Operations Index",
        "",
        "intel.root/convoys",
        "intel.root/radio"
    ] joinString endl;

    private _convoys = [
        "Convoy Board",
        "",
        "0415 - North convoy departs.",
        "Escort: MRAP x2.",
        "Route: Red."
    ] joinString endl;

    private _radio = [
        "Radio Relay",
        "",
        "Fallback frequency: 52.7",
        "Challenge word: orchard"
    ] joinString endl;

    ["intel.root/home", "Operations Index", _home, _laptop] call AE3_desktop_fnc_registerWebpage;
    ["intel.root/convoys", "Convoy Board", _convoys, _laptop] call AE3_desktop_fnc_registerWebpage;
    ["intel.root/radio", "Radio Relay", _radio, _laptop] call AE3_desktop_fnc_registerWebpage;

    [_laptop, "intel.root/home", "02:03"] call AE3_desktop_fnc_addHistoryEntry;
    [_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;

    [
        _laptop,
        "handler@lan",
        "Before dawn",
        "The convoy board moved. Check intel.root/home and follow the trail.",
        "admin@lan",
        "01:58"
    ] call AE3_desktop_fnc_addEmail;
};
```

## Combining Pages with Locked Files

```sqf
["intel.root/archive", "Archive Notice", "Archive password hint: first fruit in the radio note.", _laptop] call AE3_desktop_fnc_registerWebpage;

[
    _laptop,
    "/home/admin/Desktop/archive.txt",
    "orchard",
    "Archived route: Blue tunnel",
    "admin"
] call AE3_desktop_fnc_addLockedFile;
```

The page gives context, the locked file carries the reward.

## Combining Pages with Media

```sqf
["media\images\safehouse.jpg", "image", "/home/admin/Desktop/safehouse.jpg", [_laptop], "mission"] call AE3_desktop_fnc_registerMedia;

[
    "intel.root/safehouse",
    "Safehouse Note",
    "Photo saved locally as /home/admin/Desktop/safehouse.jpg",
    _laptop
] call AE3_desktop_fnc_registerWebpage;
```

This keeps binary media in the media system while using the browser as the clue surface.

## Addon-Provided Pages

Addon pages can be registered from server init or object initialization. Use `"all"` for global pages and targeted laptop arrays when your addon creates specific objects.

For pages that should exist on laptops initialized later, add a small registration hook around the same lifecycle where your addon sees AE3 computers become available. For media, `AE3_desktop_fnc_registerMedia` has a `"future"` target; webpage registration currently uses direct current targets or global page registration.

## URL Naming Guidelines

Good:

```text
intel.root/home
corp.local/personnel
depot.local/inventory
blacksite/a17/report
```

Risky:

```text
https://real-company.example
www.google.com
random string with spaces
```

Keep URLs easy to type, easy to remember, and consistent within the mission.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| URL exists in history but page fails | History and page registration are separate. Register the page too. |
| Page exists only on one laptop | It was targeted to that laptop. Use `"all"` or pass more laptops. |
| Page is visible too broadly | It was registered globally. Use a target object/array. |
| Content line breaks missing | Use `endl` or `joinString endl`. |
| Page not visible after JIP | Ensure registration happened on the server or via a global registry path. |

## Related Pages

- [Browser API](../Reference/Browser-API.md)
- [Desktop API](../Reference/Desktop-API.md)
- [Browser and Webpages System](../Systems/Browser-and-Webpages.md)

# Browser API

The Browser app reads registered in-game webpages and per-laptop browser history. It is a mission-intel system, not an unrestricted internet browser. Pages are created by script, Eden modules, Zeus modules, or addon registration code.

Use the Browser API when you want players to discover URLs, follow browser history trails, read intranet-style pages, or tie emails/files to a web clue.

## Page Model

A browser page has:

| Field | Type | Meaning |
| --- | --- | --- |
| URL | String | Address players type or click, for example `intel.root/convoys`. |
| Title | String | Browser title/header. |
| Content | String or Array | Text content shown in the Browser app. |
| Target | Object, array, or `"all"` | Which laptop(s) receive the page. |

Global pages are mission-wide. Targeted pages are written to selected laptop filesystems so only those machines know the page.

## URL Guidance

Use readable fictional domains:

```text
intel.root/convoys
mail.node/safehouse
depot.local/inventory
research.black/subjects/a17
```

Avoid real-world external URLs unless the mission fiction requires them. The in-game Browser is better as an internal clue system.

## Registering Webpages

### `AE3_desktop_fnc_registerWebpage`

Registers a page for the Browser app.

```sqf
[_url, _title, _content, _targets] call AE3_desktop_fnc_registerWebpage;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | String | Required | Page URL. |
| `1` | String | Required | Page title. |
| `2` | String or Array | Required | Page content. |
| `3` | Object, Array, or String | `"all"` | Laptop target(s) or `"all"`. |

Return value: none.

Example: global page.

```sqf
[
    "intel.root/home",
    "Operations Index",
    "Known pages:" + endl + "intel.root/convoys" + endl + "intel.root/frequencies",
    "all"
] call AE3_desktop_fnc_registerWebpage;
```

Example: page only on one laptop.

```sqf
[
    "intel.root/convoys",
    "Convoy Board",
    "North convoy: 0415" + endl + "Escort: MRAP x2" + endl + "Route: Red",
    _laptop
] call AE3_desktop_fnc_registerWebpage;
```

Example: same page on selected laptops.

```sqf
[
    "depot.local/inventory",
    "Depot Inventory",
    "Missing: 2 crates marked A-17.",
    [_quartermasterLaptop, _securityLaptop]
] call AE3_desktop_fnc_registerWebpage;
```

## Content Formatting

Use plain text and `endl` for line breaks:

```sqf
private _body = [
    "CONVOY BOARD",
    "",
    "0415 - North convoy departs.",
    "0430 - Radio silence.",
    "0500 - Report to relay tower."
] joinString endl;
```

Then register:

```sqf
["intel.root/convoys", "Convoy Board", _body, _laptop] call AE3_desktop_fnc_registerWebpage;
```

Arrays are accepted by the function, but string content is easiest to maintain unless your extension intentionally stores structured content.

## Browser History

### `AE3_desktop_fnc_addHistoryEntry`

Seeds a laptop browser history entry.

```sqf
[_target, _url, _timeString] call AE3_desktop_fnc_addHistoryEntry;
```

Arguments:

| Index | Type | Default | Meaning |
| --- | --- | --- | --- |
| `0` | Object or String | Required | Laptop object, laptop netId, or `"all"`. |
| `1` | String | Required | URL to add. |
| `2` | String | Random time | Display time, usually `HH:MM`. |

Example:

```sqf
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
```

Example: create a trail.

```sqf
{
    _x params ["_url", "_time"];
    [_laptop, _url, _time] call AE3_desktop_fnc_addHistoryEntry;
} forEach [
    ["mail.node/inbox", "01:58"],
    ["intel.root/home", "02:03"],
    ["intel.root/convoys", "02:47"]
];
```

History is stored in:

```text
/var/log/browser_history
```

Players can discover this through the Browser UI, the Files app, or terminal commands such as `cat`.

## Complete Browser Intel Setup

```sqf
if (isServer) then {
    private _index = [
        "Operations Index",
        "",
        "convoys - convoy schedule",
        "relay - radio relay notes"
    ] joinString endl;

    private _convoys = [
        "North convoy",
        "Departure: 0415",
        "Escort: MRAP x2",
        "Route: Red"
    ] joinString endl;

    ["intel.root/home", "Operations Index", _index, _laptop] call AE3_desktop_fnc_registerWebpage;
    ["intel.root/convoys", "Convoy Board", _convoys, _laptop] call AE3_desktop_fnc_registerWebpage;

    [_laptop, "intel.root/home", "02:03"] call AE3_desktop_fnc_addHistoryEntry;
    [_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
};
```

## Linking Browser Content to Other Systems

Useful combinations:

| System | Pattern |
| --- | --- |
| Email | Put a URL in an email body and register the page on that laptop. |
| Files | Create a note containing a URL with `AE3_filesystem_fnc_createFile`. |
| Browser history | Add a history entry without telling players directly. |
| Locked file | Put the password hint on a webpage and the protected payload in a locked file. |
| Media | Register media to the filesystem and mention the path on a webpage. |

Example:

```sqf
[_laptop, "handler@lan", "Look at this", "Check intel.root/convoys before dawn.", "admin@lan"] call AE3_desktop_fnc_addEmail;
[_laptop, "/home/admin/Desktop/route-password.txt", "redline", "Route file password accepted."] call AE3_desktop_fnc_addLockedFile;
```

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Page cannot be opened | Confirm the page was registered for that laptop or globally. |
| History entry appears but page is missing | History and page registration are separate; add both if players should open the URL. |
| Page exists on one laptop but not another | The registration was targeted. Use `"all"` or pass both laptops. |
| Line breaks do not display as expected | Build content with `endl` or `joinString endl`. |
| Dedicated server clients do not see page | Run setup on the server after laptop initialization, or use the Desktop API that routes to server. |

## Related Pages

- [Desktop API](Desktop-API.md)
- [Filesystem API](Filesystem-API.md)
- [Extending Browser Webpages](../Developer/Extending-Browser-Webpages.md)
- [Browser and Webpages System](../Systems/Browser-and-Webpages.md)

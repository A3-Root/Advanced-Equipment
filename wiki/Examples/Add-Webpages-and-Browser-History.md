# Add Webpages and Browser History

This recipe creates Browser app clues. It covers Eden Editor, Zeus, and API workflows.

Browser pages and browser history are separate:

- A webpage is the content players can read.
- A history entry is a clue that points to a URL.

If you add only history, players may see a URL that does not open. If you add only a webpage, players may not know it exists.

## Eden Editor Workflow

Use this before mission start.

### Add a Webpage in Eden

1. Place an AE3 laptop with GUI or Both interface mode.
2. Place the `AE3: Add Webpage` module.
3. Double-click the module.
4. Set `URL`, for example `intel.root/depot`.
5. Set `Title`, for example `Depot Inventory`.
6. Set `Content`, for example `Two crates moved to Grid 041-088.`.
7. Sync the module to the target laptop.

### Add Browser History in Eden

1. Place the `AE3: Add Browser History` module.
2. Double-click the module.
3. Set `URL` to the same URL, for example `intel.root/depot`.
4. Set `Time`, for example `02:47`; leave blank for a generated/random time.
5. Sync the module to the same laptop.

### Eden Testing

1. Preview the mission.
2. Log into the laptop.
3. Open the Browser app.
4. Check history.
5. Open the URL and confirm the content is readable.

## Zeus Workflow

The individual `AE3: Add Webpage` and `AE3: Add Browser History` modules are Eden modules. For live Zeus work, use the Zeus Add Intel workflow.

1. Open Zeus.
2. Use the `AE3: Add Intel` module/dialog on the target laptop.
3. Choose or configure the intel type as Webpage.
4. Enter the URL, title, and content.
5. Apply the module.
6. Use the same Add Intel workflow again for Browser History.
7. Enter the URL and displayed time.
8. Tell players through roleplay or another clue that the laptop has new browser activity.

If your Zeus build exposes separate Add Webpage/Add Browser History entries, use them the same way as Eden: configure attributes, target the laptop, and apply.

## API Workflow

Run setup on the server.

```sqf
if (isServer) then {
    [
        "intel.root/depot",
        "Depot Inventory",
        "Two crates moved to Grid 041-088." + endl + "Escort requested before dawn.",
        _laptop
    ] call AE3_desktop_fnc_registerWebpage;

    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
};
```

Create a multi-page trail:

```sqf
if (isServer) then {
    ["intel.root/home", "Operations Index", "See intel.root/depot and intel.root/radio.", _laptop] call AE3_desktop_fnc_registerWebpage;
    ["intel.root/depot", "Depot Inventory", "Crates A-17 and A-18 are missing.", _laptop] call AE3_desktop_fnc_registerWebpage;
    ["intel.root/radio", "Radio Note", "Fallback frequency: 52.7.", _laptop] call AE3_desktop_fnc_registerWebpage;

    [_laptop, "intel.root/home", "02:03"] call AE3_desktop_fnc_addHistoryEntry;
    [_laptop, "intel.root/depot", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
};
```

## Design Tips

- Keep page URLs short and typeable.
- Use fictional local domains such as `intel.root`, `depot.local`, or `mail.node`.
- Use history as a trail, not as the only clue.
- Put passwords or follow-up file paths on pages when you want layered investigation.
- Use email to tell players which URL matters.
- Use files for long reports; use browser pages for short, navigable intel.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| History entry opens nothing | Register the webpage too. |
| Page exists but players never find it | Add history, email, file, briefing, or Zeus hint pointing to the URL. |
| Page is on wrong laptop | Check the module sync or API target. |
| Players use Terminal-only laptop | Browser requires GUI/Desktop access. Set Interface Mode to GUI or Both. |
| Live Zeus page does not appear immediately | Ask players to reopen/refresh the Browser if needed. |

## Related Pages

- [Browser and Webpages](../Systems/Browser-and-Webpages.md)
- [Browser API](../Reference/Browser-API.md)
- [Desktop API](../Reference/Desktop-API.md)

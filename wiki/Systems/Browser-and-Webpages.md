# Browser and Webpages

The Browser app displays in-game webpages registered by mission scripts, modules, or addon code. Browser pages are useful for investigation, intranet sites, objective chains, fake public websites, and search-history intel.

## Register a Page

```sqf
[
    "intel.root/convoys",
    "Convoy Board",
    "North convoy departs at 0415." + endl + "Escort: two MRAPs.",
    _laptop
] call AE3_desktop_fnc_registerWebpage;
```

Targets may be one laptop, an array of laptops, or `"all"`.

## Add Browser History

Browser history is stored as `/var/log/browser_history` on the laptop filesystem.

```sqf
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
```

Use history to point players toward relevant pages without putting the link directly in a briefing.

## 3DEN and Zeus

Use the Add Webpage and Add Browser History modules to seed pages and history without scripting. Zeus can add these during play for live intel drops.

## Content Limits

Pages are text-focused mission content. Keep pages concise and readable in the in-game browser window. Use media registration when the intel is an image, video, or audio file.

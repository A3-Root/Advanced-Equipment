# Add Webpages and Browser History

## One Laptop

```sqf
[
    "intel.root/depot",
    "Depot Intranet",
    "Fuel records show deliveries every Friday at 0300.",
    _laptop
] call AE3_desktop_fnc_registerWebpage;

[_laptop, "intel.root/depot", "02:33"] call AE3_desktop_fnc_addHistoryEntry;
```

## All Laptops

```sqf
["news.local/front", "Local News", "Power outages reported near the port.", "all"] call AE3_desktop_fnc_registerWebpage;
["all", "news.local/front", "21:04"] call AE3_desktop_fnc_addHistoryEntry;
```

## Multiple Lines

```sqf
private _page = [
    "Maintenance Log",
    "Generator B failed twice this week.",
    "Temporary password: river"
];

["facility.local/maintenance", "Maintenance", _page, _laptop] call AE3_desktop_fnc_registerWebpage;
```

Players can open the page in the GUI Browser or discover it through `/var/log/browser_history`.

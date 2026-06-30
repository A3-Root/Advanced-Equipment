# Browser API

The Browser app uses mission-registered pages and per-laptop history.

## Register Webpage

```sqf
[
    "intel.root/convoys",
    "Convoy Board",
    ["North convoy", "Departure: 0415", "Escort: MRAP x2"],
    _laptop
] call AE3_desktop_fnc_registerWebpage;
```

Arguments:

| Index | Type | Meaning |
| --- | --- | --- |
| 0 | String | URL, for example `intel.root/convoys`. |
| 1 | String | Page title. |
| 2 | String or array | Page content. |
| 3 | Object, array, or string | Target laptop(s), default `"all"`. |

## Add Browser History

```sqf
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;
```

Arguments:

| Index | Type | Meaning |
| --- | --- | --- |
| 0 | Object or string | Laptop, netId, or `"all"`. |
| 1 | String | URL. |
| 2 | String | Optional displayed time. Blank picks a random time. |

History is stored in `/var/log/browser_history` and can be read with the Files app or `cat`.

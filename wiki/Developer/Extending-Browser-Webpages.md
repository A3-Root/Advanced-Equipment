# Extending Browser Webpages

The Browser app is text-page oriented. Register pages with URLs and titles, then optionally seed browser history.

```sqf
["corp.local/home", "Corporate Home", "Welcome to the intranet.", "all"] call AE3_desktop_fnc_registerWebpage;
["all", "corp.local/home", "08:00"] call AE3_desktop_fnc_addHistoryEntry;
```

For addon-provided web content, register pages during mission initialization or after a laptop is created. Use targeted pages when only one laptop should contain the content.

For media-heavy content, register media files and link players to them through a page, file, email, or browser history entry.

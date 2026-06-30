# Intel, Mail, Chat, and Media

AE3 desktop systems can seed mission intel through email, browser pages, browser history, media files, chat, calendar entries, map data, CCTV cameras, and locked files.

## Email

```sqf
[
    _laptop,
    "informant@lan",
    "Convoy route",
    "They leave the depot at 0415.",
    "admin@lan",
    "03:20",
    true,
    true
] call AE3_desktop_fnc_addEmail;
```

## Media

```sqf
[
    "media\\images\\photo.jpg",
    "image",
    "/home/admin/Desktop/photo.jpg",
    _laptop,
    "mission",
    false
] call AE3_desktop_fnc_registerMedia;
```

## Locked Files

```sqf
[_laptop, "/home/admin/codes.txt", "river", "Code: 4812"] call AE3_desktop_fnc_addLockedFile;
```

Players can unlock from the GUI prompt or with the terminal `unlock` command.

# Add Intel, Mail, Chat, or Media

## Email

```sqf
[_laptop, "handler@lan", "Pickup", "Meet at warehouse 3.", "admin@lan", "01:22", true, true] call AE3_desktop_fnc_addEmail;
```

## Calendar

```sqf
[_laptop, "2028-07-03", "Courier", "Arrives at checkpoint after sunset."] call AE3_desktop_fnc_addCalendarEvent;
```

## Media

```sqf
["media\\briefing.jpg", "image", "/home/admin/Desktop/briefing.jpg", _laptop, "mission", false] call AE3_desktop_fnc_registerMedia;
```

## CCTV

```sqf
["Gate Camera", _cameraObject, [0, 0.2, 0.1], -1] call AE3_desktop_fnc_registerCamera;
```

Use webpages for text intel, media for audiovisual clues, and email/history when players should infer where to look next.

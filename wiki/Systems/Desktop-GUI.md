# Desktop GUI

The Desktop GUI is the graphical operating system for AE3 laptops. It gives players windows, app icons, and familiar computer workflows — mouse-driven rather than typed.

## Built-In Apps

| App | Purpose |
| --- | --- |
| Terminal | Command line inside the desktop. |
| Files | Folder and file browsing. |
| Settings | Desktop and system settings. |
| Notepad | Text note workflow. |
| Mail | Inbox and message reading. |
| Chat | Network chat. |
| Browser | Mission webpages and history. |
| Calendar | Scheduled events. |
| Map | Map-focused information. |
| CCTV | Registered camera feeds. |
| Music | Audio playback. |
| SysInfo | System and device information. |

The exact apps available depend on laptop configuration and mission setup — see [Desktop Apps](../Reference/Desktop-Apps.md) for the full per-app reference and [Register Desktop Apps](../Examples/Register-Desktop-Apps.md) if you're adding a custom app from another addon.

## How Players Use It

Players open the laptop through ACE, choose the desktop action if available, log in if required, and use apps. The mission maker decides whether the desktop is the only interface (Interface Mode `gui`) or whether players can also use the terminal (`both`).

## Good GUI Mission Content

Use the GUI desktop for:

- Emails with sender/recipient context (Mail app).
- Browser pages with readable clues and history trails (Browser app).
- Documents and folders (Files app).
- Images or audio/video evidence (Media, via Files/Browser).
- Calendar schedules (Calendar app).
- CCTV feeds (CCTV app).

Avoid requiring terminal-only knowledge if a laptop is configured as GUI-only — a clue that only exists as a hidden file with no Files-app entry point is effectively invisible on a `gui`-mode laptop unless it's reachable through Files navigation.

## Mission-Maker Setup

In 3DEN:

1. Set laptop Interface Mode to `gui` or `both`.
2. Add a user if login should be required (`AE3: Add User`).
3. Add desktop content modules such as `AE3: Add Email`, `AE3: Add Webpage`, `AE3: Add Browser History`, `AE3: Add Media`, `AE3: Add File`, `AE3: Add Directory`, or `AE3: Add Passworded File`.
4. Sync each module to the laptop.
5. Preview and open the desktop as a player.

## Related Pages

- [Desktop API](../Reference/Desktop-API.md) — scripted app registration, content, and JS-bridge details.
- [Desktop Apps](../Reference/Desktop-Apps.md) — per-app field reference.
- [Extending Desktop GUI](../Developer/Extending-Desktop-GUI.md) — building a new app as an addon developer.
